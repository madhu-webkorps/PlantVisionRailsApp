class SeedAnalysesController < ApplicationController
  before_action :set_seed, only: [:show]

  def index
    sort_column = %w[name scientific_name status quality created_at].include?(params[:sort]) ? params[:sort] : "created_at"
    sort_direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"

    @seeds = Seed.where(error: [nil, ""]).order("#{sort_column} #{sort_direction}")
  end

  def new
    @seed = Seed.new
  end

  def create
    @seed = Seed.new
    @seed.status = :pending
    @seed.file.attach(seed_params[:file]) if seed_params[:file]
    @seed.status = :processing if @seed.file.attached?

    if @seed.save
      SeedAnalysisWorker.perform_async(@seed.id)

      redirect_to seed_analysis_path(@seed), notice: 'Seed File uploaded. Processing will begin shortly'
    else
      flash.now[:alert] = @seed.errors.full_messages.to_sentence
      render :new
    end
  end

  def set_seed
    @seed
  end

  def destroy
    @seed = Seed.find(params[:id])
    if @seed.destroy
      redirect_to seed_analyses_path, notice: 'Seed analysis was successfully deleted.'
    else
      redirect_to seed_analyses_path, alert: 'Failed to delete seed analysis.'
    end
  end

  private

  def set_seed
    @seed = Seed.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "The requested seed was not found."
    redirect_to seed_analyses_path
  end

  def seed_params
    params.require(:seed).permit(:file)
  end
end
