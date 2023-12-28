window.addEventListener("load", function() {
    document.body.addEventListener('drop', function(event) {
        event.preventDefault();
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            const file = files[0];
            if(file.type.startsWith('image/')) {
                const reader = new FileReader();
                reader.onload = function(loadEvent) {
                    window.dispatchEvent(new CustomEvent("fileDropped", {
                        detail: loadEvent.target.result
                    }));
                };
                reader.readAsDataURL(file); // Read as Data URL for images
            }
        }
    });

    document.body.addEventListener('dragover', function(event) {
        event.preventDefault();
    });
});
