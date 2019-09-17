var app = new Vue({
  el: '#app',
  data: {
    results: [{
      job_id: "131312312312",
      status: "done",
      filename: "my very long filenam",
      file_size: 4333
    },{
      job_id: "131312312312",
      status: "done",
      filename: "my very long filenam",
      file_size: 4333
    }],
    isBW: false,
    filename: null,
    file_size: null,
    error_message: null
  },
  methods: {
    updateFilename: function(e) {
      const form = document.getElementById('pdf-form');
      const formData = new FormData(form);
      app.filename = formData.get("pdf").name
      app.file_size = formData.get("pdf").size
    },
    format_bytes: function(bytes) {
      return (bytes/1024).toFixed(0) + "KB";
    },
    status_to_icon: function(status) {
      let dict = {
        "uploading": "fas fa-file-upload",
        "uploaded": "far fa-clock",
        "compressing": "fas fa-cogs",
        "publishing": "fas fa-cloud-upload-alt",
        "failed": "fas fa-exclamation-circle",
        "done": "fas fa-check-circle"
      }
      return dict[status]
    },
    clearError: function(e) {
      app.error_message = null;
    },
    handleInvalidFile: function(e) {
      app.error_message = "Please, select a PDF";
    }
  }
})

// On form submission
document.addEventListener('submit', e => {
  const form = e.target;
  const formData = new FormData(form);
  const color = formData.get("bw") == "on" ? "Gray" : "LeaveColorUnchanged"
  const color_string = "color=" + color
  const dpi_string = "dpi=" + formData.get("dpi")
  const filename = formData.get("pdf").name
  const file_size = formData.get("pdf").size

  fetch(form.action + "?" + [color_string, dpi_string].join("&"), {
      method: form.method,
      body: formData
  }).then(res => res.json())
  .then(data => {
    if (data.error) {
      console.log("Error: " + data.error)
      app.error_message = data.error
      return null
    }
    app.results = app.results.concat({
      job_id: data.job_id,
      status: data.status,
      filename: filename,
      file_size: file_size
    })
    socket = new WebSocket('ws://' + window.location.host + '/' + data.job_id);
    socket.addEventListener('open', function (event) {
      socket.send('ping');
    });
    socket.addEventListener('error', function (event) {
      console.log("error", event);
    });
    socket.addEventListener('close', function (event) {
      console.log("close", event);
    });
    // Listen for messages
    socket.addEventListener('message', function (event) {
      console.log('Message from server ', event.data);
      data = JSON.parse(event.data)
      // TODO: handle case where data.error != null
      app.results = app.results.map(job => {
        if(job.job_id == data.job_id) {
          job.status = data.status
          if(data.status == "done") {
            job.compressed_size = data.bytes
            job.location = "/compressed/" + JSON.parse(event.data).job_id
          }
        }
        return job
      })
    });
  })

  e.preventDefault();
});