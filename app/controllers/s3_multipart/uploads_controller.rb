module S3Multipart
  class UploadsController < ApplicationController
    def create
      begin
        response = Upload.initiate(params)
        upload = Upload.create(key: response["key"], upload_id: response["upload_id"], name: response["name"])
        response["id"] = upload["id"]
      rescue
        response = {error: 'There was an error initiating the upload'}
      ensure
        render :json => response
      end
    end

    def update
      return complete_upload if params[:parts]
      return sign_batch if params[:content_lengths]
      return sign_part if params[:content_length]
    end 

    private 

    def sign_batch
      begin
        response = S3Multipart::Uploader.sign_batch(params)
      rescue
        response = {error: 'There was an error in processing your upload'}
      ensure
        render :json => response
      end
    end

    def sign_part
      begin
        response = S3Multipart::Uploader.sign_part(params)
      rescue
        response = {error: 'There was an error in processing your upload'}
      ensure
        render :json => response
      end
    end

    def complete_upload
      begin
        response = S3Multipart::Uploader.complete(params)
        
        upload = Upload.find_by_upload_id(params[:upload_id])
        upload.update_attributes(location: response[:location])
        upload.run_callback
      rescue
        response = {error: 'There was an error completing the upload'}
      ensure
        render :json => response
      end
    end

  end
end