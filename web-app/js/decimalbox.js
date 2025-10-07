zk.afterLoad(grepCommaDecimal());

function grepCommaDecimal() {
	jq('.z-decimalbox input, .z-decimalbox-rounded input').each(function () {
		if (!jq(this).attr('comma')) {
			jq(this).attr('comma', true)
			jq(this).keypress(function (e) {
				// '46' is the keyCode for '.'
				if (e.keyCode == '46' || e.charCode == '46') {
					// IE
					if (document.selection) {
						// Determines the selected text. If no text selected,
						// the location of the cursor in the text is returned
						var range = document.selection.createRange();
		               // Place the comma on the location of the selection,
		               // and remove the data in the selection
		               range.text = ',';
		               // Chrome + FF
		           } else if(this.selectionStart || this.selectionStart == '0') {
		               // Determines the start and end of the selection.
		               // If no text selected, they are the same and
		               // the location of the cursor in the text is returned
		               // Don't make it a jQuery obj, because selectionStart 
		               // and selectionEnd isn't known.
		               var start = this.selectionStart;
		               var end = this.selectionEnd;
		               // Place the comma on the location of the selection,
		               // and remove the data in the selection
		               jq(this).val(jq(this).val().substring(0, start) + ','
		                       + jq(this).val().substring(end, jq(this).val().length));
		               // Set the cursor back at the correct location in 
		               // the text
		               this.selectionStart = start + 1;
		               this.selectionEnd = start + 1;
		           } else {
		               // if no selection could be determined, 
		               // place the comma at the end.
		               jq(this).val($(this).val() + ',');             
		           }
		           return false;
		       }
		   });
		}
	});
	
}