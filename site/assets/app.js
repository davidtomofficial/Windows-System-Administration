import { planRange, planList } from '../demos/name-planner.mjs';
const form = document.getElementById('planner-form');
const mode = document.getElementById('mode');
const rangeFields = document.getElementById('range-fields');
const listFields = document.getElementById('list-fields');
const output = document.getElementById('planner-output');
const error = document.getElementById('planner-error');
const status = document.getElementById('planner-status');
const copy = document.getElementById('copy-results');
let generated = '';
function selectMode() {
  rangeFields.hidden = mode.value !== 'range';
  listFields.hidden = mode.value !== 'list';
}
function clearResults() {
  generated = '';
  error.hidden = true;
  error.textContent = '';
  copy.disabled = true;
  output.textContent = 'No validated output yet.';
}
mode.addEventListener('change', () => {
  selectMode(); clearResults();
  status.textContent = 'Input mode updated. Generate a new synthetic example.';
});
form.addEventListener('submit', (event) => {
  event.preventDefault();
  clearResults();
  try {
    const maximum = form.elements.maximum.value;
    const names = mode.value === 'range'
      ? planRange({prefix: form.elements.prefix.value, start: form.elements.start.value, end: form.elements.end.value, pad: form.elements.pad.value, maximum})
      : planList(form.elements.names.value, maximum);
    generated = names.join('\n');
    output.textContent = generated;
    copy.disabled = false;
    status.textContent = names.length + ' synthetic ' + (names.length === 1 ? 'name' : 'names') + ' generated locally. No device has been queried.';
  } catch (caught) {
    error.textContent = caught instanceof Error ? caught.message : 'Unable to validate this selection.';
    error.hidden = false;
    status.textContent = 'Validation failed; no results were generated.';
  }
});
form.addEventListener('reset', () => {
  rangeFields.hidden = false;
  listFields.hidden = true;
  clearResults();
  status.textContent = 'Form reset. Generate a new synthetic example.';
});
copy.addEventListener('click', async () => {
  if (!generated) return;
  try {
    await navigator.clipboard.writeText(generated);
    status.textContent = 'Synthetic names copied to the clipboard.';
  } catch {
    status.textContent = 'Clipboard unavailable. Select the output and copy it manually.';
    output.focus();
  }
});
selectMode();
