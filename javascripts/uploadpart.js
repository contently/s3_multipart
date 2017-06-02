// Upload part constructor
function UploadPart(blob, key, upload) {
  var part, xhr;

  part = this;

  this.size = blob.size;
  this.blob = blob;
  this.num = key;
  this.upload = upload;

  this.xhr = xhr = upload.createXhrRequest();
  xhr.onload = function() {
    upload.handler.onPartSuccess(upload, part);
  };
  xhr.onerror = function() {
    upload.handler.onError(upload, part);
  };
  xhr.upload.onprogress = _.throttle(function(e) {
    if (e.lengthComputable) {
      upload.inprogress[key] = e.loaded;
    }
  }, 1000);
};

UploadPart.prototype.activate = function() {
  var upload_part = this;
  this.upload.signPartRequest(this.upload.id, this.upload.object_name, this.upload.upload_id, this, function(response) {
    upload_part.xhr.open('PUT', '//'+upload_part.upload.bucket+'.s3.amazonaws.com/'+upload_part.upload.object_name+'?partNumber='+upload_part.num+'&uploadId='+upload_part.upload.upload_id, true);

    upload_part.xhr.setRequestHeader('x-amz-date', response.date);
    upload_part.xhr.setRequestHeader('Authorization', response.authorization);

    upload_part.xhr.send(upload_part.blob);
    upload_part.status = "active";
  });
};

UploadPart.prototype.pause = function() {
  this.xhr.abort();
  this.status = "paused";
};

UploadPart.prototype.cancel = function() {
  this.xhr.abort();
  this.status = "cancelled";
};
