class StoresController < ApplicationController
  before_action :set_store, only: [:show, :edit, :update, :destroy]

  # GET /stores
  # GET /stores.json
  def index
    @stores = Store.all.sort_by(&:city)
    @cities = @stores.map(&:city).uniq
  end
  
  def search
    @product_id = params[:query][:product_id]
    @stores = Store.where('city = ? OR city = ? OR city = ? OR city = ? OR city = ?', params[:query][:city_1], params[:query][:city_2], params[:query][:city_3], params[:query][:city_4], params[:query][:city_5]).sort_by(&:city)
    @output = {}
    @stores.each_with_index do |s,i|
      puts "Collecting information for record ##{i+1}: Store #{s.id}...."
      @output[s.store_id] = s.get_data_single(@product_id)
      # fill store phone number and update latitude and longitude to be more precise
      if s.phone.nil?
        # update the actual record, not the eager-loaded record
        Store.find(s.id).update(lat: @output[s.store_id]["latitude"], long: @output[s.store_id]["longitude"], phone: @output[s.store_id]["phoneNumber"]["FormattedPhoneNumber"])
      end
    end
  end

  # GET /stores/1
  # GET /stores/1.json
  def show
  end

  # GET /stores/new
  def new
    @store = Store.new
  end

  # GET /stores/1/edit
  def edit
  end

  # POST /stores
  # POST /stores.json
  def create
    @store = Store.new(store_params)

    respond_to do |format|
      if @store.save
        format.html { redirect_to @store, notice: 'Store was successfully created.' }
        format.json { render :show, status: :created, location: @store }
      else
        format.html { render :new }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stores/1
  # PATCH/PUT /stores/1.json
  def update
    respond_to do |format|
      if @store.update(store_params)
        format.html { redirect_to @store, notice: 'Store was successfully updated.' }
        format.json { render :show, status: :ok, location: @store }
      else
        format.html { render :edit }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stores/1
  # DELETE /stores/1.json
  def destroy
    @store.destroy
    respond_to do |format|
      format.html { redirect_to stores_url, notice: 'Store was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_store
      @store = Store.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def store_params
      params.fetch(:store, {})
    end
end
