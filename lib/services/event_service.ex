defmodule Aprb.Service.EventService do
  alias Aprb.{Repo, Topic}
  def receive_event(event, topic) do
    proccessed_message = process_event(event, topic)
    # broadcast a message to a topic
    for subscriber <- get_topic_subscribers(topic) do
      Slack.Web.Chat.post_message("##{subscriber.channel_name}", proccessed_message[:text], %{attachments: proccessed_message[:attachments], unfurl_links: proccessed_message[:unfurl_links], as_user: true})
    end
  end

  defp process_event(event, topic) do
    event = Poison.decode!(event.value)
    case topic do
      "users" ->
        %{text: ":heart: #{cleanup_name(event["subject"]["display"])} #{event["verb"]} https://www.artsy.net/artist/#{event["properties"]["artist"]["id"]}",
          unfurl_links: true }

      "subscriptions" ->
        %{text: "",
          attachments: "[{
                          \"title\": \":moneybag: Subscription #{event["verb"]}\",
                          \"title_link\": \"https://admin-partners.artsy.net/subscriptions/#{event["object"]["id"]}\",
                          \"fields\": [
                            {
                              \"title\": \"By\",
                              \"value\": \"#{cleanup_name(event["subject"]["display"])}\",
                              \"short\": true
                            },
                            {
                              \"title\": \"Partner\",
                              \"value\": \"#{event["properties"]["partner"]["name"]}\",
                              \"short\": true
                            }
                          ]
                        }]",
          unfurl_links: false }

      "inquiries" ->
        %{text: ":shaka: #{cleanup_name(event["subject"]["display"])} #{event["verb"]} on https://www.artsy.net/artwork/#{event["properties"]["inquireable"]["id"]}",
          unfurl_links: true }

      "purchases" ->
        %{text: ":shake: #{cleanup_name(event["subject"]["display"])} #{event["verb"]} https://www.artsy.net/artwork/#{event["properties"]["artwork"]["id"]}",
          attachments: "[{
                          \"fields\": [
                            {
                              \"title\": \"Price\",
                              \"value\": \"#{format_price(event["properties"]["sale_price"] || 0)}\",
                              \"short\": true
                            }
                          ]
                        }]",
          unfurl_links: true }
      "bidding" ->
        artwork_data = fetch_sale_artwork(event["lotId"])
        %{
          text: ":gavel: #{event["type"]} on #{artwork_data[:permalink]}",
          attachments: "[{
                          \"fields\": [
                            {
                              \"title\": \"Amount\",
                              \"value\": \"#{format_price((event["amountCents"] || 0) / 100)}\",
                              \"short\": true
                            },
                            {
                              \"title\": \"Lot number\",
                              \"value\": \"#{artwork_data[:lot_number]}\",
                              \"short\": true
                            },
                            {
                              \"title\": \"Paddle number\",
                              \"value\": \"#{event["bidder"]["paddleNumber"]}\",
                              \"short\": true
                            }
                          ]
                        }]",
          unfurl_links: true
         }
    end
  end

  defp fetch_sale_artwork(lot_id) do
    sale_artwork_response = Gravity.get!("/sale_artworks/#{lot_id}").body
    %{
      permalink: sale_artwork_response["_links"]["permalink"]["href"],
      lot_number: sale_artwork_response["lot_number"]
    }
  end

  defp get_topic_subscribers(topic_name) do
    topic = Repo.get_by(Topic, name: topic_name)
              |> Repo.preload(:subscribers)
    topic.subscribers
  end

  defp cleanup_name(full_name) do
    full_name
      |> String.split
      |> List.first
  end

  defp format_price(price) do
    if price do
      Money.to_string(Money.new(round(price * 100), :USD), symbol: false)
    else
      "N/A"
    end
  end
end
