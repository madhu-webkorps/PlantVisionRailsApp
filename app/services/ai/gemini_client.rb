# app/services/ai/gemini_client.rb
require "base64"
require "net/http"
require "json"
require "httparty"

module Ai
  class GeminiClient
    ENDPOINT = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent".freeze

    def initialize
      @api_key = ENV.fetch("GOOGLE_GEMINI_API_KEY")
    end

    # Public API

    def analyze_image(file)
      analyze_file(file)
    end

    def analyze_pdf(file)
      analyze_file(file)
    end

    private

    def analyze_file(file)
      base64_data = Base64.strict_encode64(file.download)
      body = {
        contents: [
          {
            parts: [
              { text: seed_prompt },
              { inline_data: { mime_type: file.content_type, data: base64_data } }
            ]
          }
        ]
      }

      call_api(body)
    end

    def seed_prompt
      <<~PROMPT
        You are a seed identification expert. Based on the uploaded file, identify the seed,
        provide its name and scientific name, nutritional and medicinal benefits, seed quality, and a detailed description.
        Return the answer in a structured JSON format.

        If the uploaded image is not a valid seed image, return:
        {
          "error": "The uploaded image is not a valid seed image. Please upload a clear, close-up image of a seed."
        }

        If the uploaded PDF does not contain any valid seed-related information or images, return:
        {
          "error": "The uploaded PDF does not contain valid seed information. Please upload a document with clear details or images of a seed."
        }

        Example output for valid input:
        {
          "name": "Sunflower",
          "scientific_name": "Helianthus annuus",
          "nutritional_benefits": "Rich in vitamin E, magnesium, and selenium.",
          "medicinal_benefits": "May help reduce inflammation and improve heart health.",
          "quality": "good",
          "description": "Sunflower seeds are the edible seeds of the sunflower plant, known for their high nutritional value and health benefits. They are commonly consumed as a healthy snack and are a good source of antioxidants."
        }
      PROMPT
    end

    def call_api(body_hash)
      uri = URI("#{ENDPOINT}?key=#{@api_key}")

      response = HTTParty.post(uri,
        headers: { "Content-Type" => "application/json" },
        body: body_hash.to_json
      )

      if response.code == 200
        raw_text = JSON.parse(response.body).dig("candidates", 0, "content", "parts", 0, "text")
        cleaned = raw_text&.gsub(/```json|```/, "")&.strip
        JSON.parse(cleaned) rescue { error: "Failed to parse AI response." }
      else
        Rails.logger.error "[GeminiClient] API Error #{response.code}: #{response.body}"
        { error: "Gemini API error #{response.code}" }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "[GeminiClient] JSON parse error: #{e.message}"
      { error: "Invalid JSON response from Gemini API." }
    rescue StandardError => e
      Rails.logger.error "[GeminiClient] Request failed: #{e.message}"
      { error: "Failed to contact Gemini API." }
    end
  end
end
