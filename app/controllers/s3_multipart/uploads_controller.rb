module S3Multipart
  class UploadsController < ApplicationController

    def create
      begin
        upload = Upload.create(upload_params_to_unsafe_h)
        upload.execute_callback(:begin, session)
        response = upload.to_json
      rescue FileTypeError, FileSizeError => e
        response = {error: e.message}
      rescue => e
        logger.error "EXC: #{e.message}"
        logger.error e.backtrace
        response = {
          error_message: t("s3_multipart.errors.create"),
          error: e.message
        }
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
          response = Upload.sign_batch(upload_params_to_unsafe_h)
        rescue => e
          logger.error "EXC: #{e.message}"
          response = {
            error_message: t("s3_multipart.errors.update"),
            error: e.message
          }
        ensure
          render :json => response
        end
      end

      def sign_part
        begin
          response = Upload.sign_part(upload_params_to_unsafe_h)
        rescue => e
          logger.error "EXC: #{e.message}"
          response = {
            error_message: t("s3_multipart.errors.update"),
            error: e.message
          }
        ensure
          render :json => response
        end
      end

      def complete_upload
        begin
          response = Upload.complete(upload_params_to_unsafe_h)
          upload = Upload.find_by_upload_id(params[:upload_id])
          upload.update_attributes(location: response[:location])
          upload.execute_callback(:complete, session)
        rescue => e
          logger.error "EXC: #{e.message}"
          response = {
            error_message: t("s3_multipart.errors.complete"),
            error: e.message
          }
        ensure
          render :json => response
        end
      end

      def upload_params_to_unsafe_h
        params.to_unsafe_h
      end
    end
end
