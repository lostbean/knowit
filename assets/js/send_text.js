export const SendText = {
  mounted() {
    this.el.addEventListener("mousedown", (event) => {
      this.send();
    });

    this.el.addEventListener("touchstart", (event) => {
      this.send();
    });

    const textarea = document.getElementById("text_input");
    if (textarea) {
      textarea.addEventListener("keydown", (e) => {
        if ((e.ctrlKey || e.metaKey) && (e.key == 13 || e.key == 10 || (e.key == "Enter"))) {
          this.send();
        }
      });
    }
  },

  send() {
    const text_area = document.getElementById("text_input");
    this.pushEvent("text_input", text_area.value);
    text_area.value = "";
  },
};