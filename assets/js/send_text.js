export const SendText = {
  mounted() {
    this.el.addEventListener("mousedown", (event) => {
      this.send();
    });

    this.el.addEventListener("touchstart", (event) => {
      this.send();
    });

    this.el.addEventListener("keydown", (e) => {
      if (e.key == "Enter" && e.shiftKey == false) {
        this.send();
      }
    })
  },

  send() {
    const text_area = document.getElementById("text_input");
    this.pushEvent("text_input", text_area.value);
    text_area.value = "";
  },
};