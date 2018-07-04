import { Controller } from "stimulus"

/***
 * Confirmable controller
 *
 * Use to have the user confirm a value, the to be confirmed value should be the `input` target,
 * the user should type the value in the input which is the `confirmation` target.
 *
 * If a `result` target is present it will get the data-correct or data-incorrect class assigned.
 */
export default class extends Controller {
  static targets = [];

  connect() {
    const self = this;
    console.log("Test");
  }

  disconnect() {
  }
}

