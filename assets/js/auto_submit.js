export const AutoSubmit = {
  mounted() {
    const original_value = this.el.getAttribute("value-original");
    this.el.addEventListener("focusout", (event) => {
      const hasChanged = this.el.innerText !== original_value;
      if (hasChanged) {
        const set_id = this.el.getAttribute("value-rename-set-id");
        this.pushEvent("rename_experiment_set", { rename_to: this.el.innerText, rename_set_id: set_id });
      }
    });
  }
};