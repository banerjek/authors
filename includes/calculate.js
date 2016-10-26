/******************************************
contents of data files are stored in variables
named after the search value in js files. For
********************************************/

var charstrokes;
var userinput;
var search;
var fixarray = [];
var lastuserinput = '';
var lastsearch = '';
var lastarray = [];
var pastinput = [];
var pastresults = {};
var pastarrays = {};
var checksearch = 0;
var checkinput = 0;


function getPage(sURL) {

	document.getElementById('results').innerHTML = document.getElementById('results').innerHTML + '<p /><b>'

  var wind= window.open(sURL, 'NewWindow', 'width=600,height=600,scrollbars=yes,resizable=yes');
   wind.focus();
   if (wind.opener == null){
         wind.opener = self;
   }
}
function clearvalues() {
	lastuserinput = '';
	lastarray = [];
	lastsearch = '';
	pastinput = [];
	pastresults = {};
	pastarrays = {};
	checksearch = 0;
	checkinput = 0;
	}	

function searchEntry(userinput, entry) {
	userinput = userinput.toLowerCase();
	entry = entry.toLowerCase();
	terms = userinput.split(" ");
	returnfound = 0;

	if (terms[0].length > 2) {
		if (entry.indexOf(terms[0]) > -1) {
			returnfound = 1;

			for (foundit = 1; foundit < terms.length; foundit++) {
				if (entry.indexOf(terms[foundit]) > -1) {
					returnfound = 1;
					} else {
						returnfound = 0;	
						break;
						}
					}

			} else {
			returnfound = 0;	
			}
		}

return returnfound;
}

function getFixed(obj_f) {
	var results;
	fixedval = obj_f.fixfield.value;
	document.getElementById('results').innerHTML = '<div id="fixed">' + fixarray[fixedval] + '</div>';
	return;
}

function makeList(resultarray, header) {
	var found = 0;
	founditems = '<table><tr><th>' + header + '</th></tr>\n';

	for (x=0; x<=resultarray.length-1; x++) {
		found += 1;
		heading = resultarray[x];	

		if (found % 2 == 0) {
			founditems += '<tr><td style="background: #c6d6ee;">' + heading;
			}
			else
			{
			founditems += '<tr><td>'
			+ heading;
			}
		founditems += '</td></tr>';
	}
	founditems += '</table><p />'
	document.getElementById('results').innerHTML = founditems;
}


function process(obj_f) {

  userinput = obj_f.userinput.value;
	userinput.trim();
	userinput = userinput.toUpperCase();

		if (userinput.length > 2) {
			if (lastuserinput.length > 2) {
				if (checksearch == 1) {
					// return results from previously executed search if possible 
					if (checksearch == 1) {
						if (pastresults[userinput]) {
							document.getElementById('results').innerHTML = pastresults[userinput];
							lastarray = pastarrays[userinput];
							return;
							} 
						}
					// Compare with previous search
					if (pastinput[userinput.length - 1] == userinput.substring(0, userinput.length - 1)) {
						checkinput = 1;
						} else {
						checkinput = 0;
						}
					}
				if (checksearch == 0 || checkinput == 0){
					clearvalues();
				}
			}
		} else {
		document.getElementById('results').innerHTML = '<table><tr><th>Search Results</th></tr><tr><td>Please enter at least three characters</td></tr></table>';
		return;
		}
	lastuserinput = userinput;
	pastinput[userinput.length] = userinput;

/************************
allow forced subject search
**************************/
   
	if (userinput.length > 2) {
		body=extract();
		pastresults[userinput] = body;
		document.getElementById('results').innerHTML = body;
		}
return;
}


/***********************************
************************************

Looks for data input by user in
tables and outputs data to result
screen

************************************
***********************************/

function extract() {
var resultarray = new Array();
var cellarray = new Array();
var founditems = '';
var found = 0;
var weblink = '';
var webbase = '';
var regmatch = '\\b' + userinput;
var recno = '';
var subs = '';
var parentorg = '';

var regexsearch = new RegExp(regmatch, "i");

	if (lastarray.length > 0) {
		resultarray = lastarray;
		lastarray = [];
		} else {
		resultarray = authors.split("\@");
		}
	founditems += '<table><tr><th width="25%">Unit</th><th width="30%">Subunits detected</th><th>Individual authors</th></tr>\n';

	for (x=0; x<=resultarray.length-1; x++) {
		if (searchEntry(userinput, resultarray[x]) == 1) {
			lastarray[found] = resultarray[x];
			found += 1;
			cellarray = resultarray[x].split("\t");	
			recno = cellarray[0];
			subs = suborgs[recno];

			if (!subs) {
				subs = '';
				}

			parentorg = parentorgs[recno];

			if (!parentorg) {
				parentorg = '';
				} else {
				parentorg = "<br />(" + parentorg + ')';
				}

			if (found < 500) {
				if (found % 2 == 0) {

					founditems += '<tr><td style="background: #c6d6ee;">'
					+ cellarray[1] + parentorg
					+ '</td><td style="background: #c6d6ee;">'
					+ subs 
					+ '</td><td style="background: #c6d6ee;">'
					+ cellarray[2]
					+ '</a></td></tr>'
					+ '\n';

					}
					else
					{
					founditems += '<tr><td>'
					+ cellarray[1] + parentorg
					+ '</td><td>'
					+ subs 
					+ '</td><td>'
					+ cellarray[2]
					+ '</td></tr>'
					+ '\n';
					}
				}
			}
		}
	if (found >= 500) {
		founditems += '<tr><td></center><h2>' + found + ' retrievals. Displaying first 500</h2></center></td></tr>';
	}
	founditems += '</table><p />'
	+'<center class="red"><b></b>';

    if (found == 0) {
		founditems = notfound();
		}
	pastarrays[userinput] = lastarray;
	return founditems;
	
	founditems += '</table>';

	if (found == 0) {
		founditems = notfound();			
		}
	return founditems;
}


/***********************************
************************************
 
Default no items found message

************************************
************************************/

function notfound() {
	return "<center><h1>No matches were found. Please try again</h1></center>";
}

