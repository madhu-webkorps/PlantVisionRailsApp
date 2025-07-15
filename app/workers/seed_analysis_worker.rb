class SeedAnalysisWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(seed_id)
    seed = Seed.find_by(id: seed_id)
    return unless seed&.file&.attached?

    ai_result = analyze_file(seed.file)

    if ai_result["error"].present?
      seed.update(status: :completed, error: ai_result["error"])
    else
      seed.update(format_ai_response(ai_result))
    end
  rescue => e
    Rails.logger.error("[SeedAnalysisWorker] Failed for Seed ID #{seed_id}: #{e.message}")
    raise
  end

  private

  def analyze_file(file)
    client = Ai::GeminiClient.new
    case file.blob.content_type
    when /\Aimage\//
      client.analyze_image(file)
    when "application/pdf"
      client.analyze_pdf(file)
    else
      client.analyze_file(file)
    end
  end

  def format_ai_response(response)
    {
      name: response["name"] || response["scientific_name"] || "Unknown",
      scientific_name: response["scientific_name"] || "Unknown",
      description: response["description"] || "No description available",
      nutritional_benefits: response["nutritional_benefits"] || "No nutritional benefits available",
      medicinal_benefits: response["medicinal_benefits"] || "No medicinal benefits available",
      quality: response["quality"] || "unknown",
      status: "completed"
    }
  end
end
