// Farbe aus ColorPicker auslesen
var theInput = document.getElementById("kb_selected_color");
var theColor = theInput.value;
theInput.addEventListener("input", function() {

// Farcode (Hex) schreiben
document.getElementById("hex").innerHTML = theInput.value;

// Farbvariable schreiben
document.documentElement.style.setProperty('--kb-color',theInput.value);
}, false);
