//=============================================================================
//  Sight Reading Trainer Plugin
//  
//  Allows to create random notes to train sight reading.
//  Find it at: https://musescore.org/en/project/sight-reading-trainer and 
//  GitHub: https://github.com/kspgh/sight-reading-trainer
//  
//
//  Version: 1.0.6
//	- Corrected the title of the training score from "Site Reading Trainer" to "Sight Reading Trainer"
//
//  Version: 1.0.5
//	- added Element.TIMESIG to indicate that measures are in 4/4
//	- added support <.> notes
//
//
//  Version: 1.0.4
//  - configuration appears as composer. This helps to reproduce a radom score with the same configuration if one saves the score
//
//  Version: 1.0.3
//  - fixed issue: https://musescore.org/en/node/328538
//
//  Version: 1.0.2
//  - fixed another bug with training level control
//  - display the version on top of the dialog
//  - fixed an issue with the last Training level info label
//
//  Version: 1.0.1
//  - Bugfix: https://musescore.org/en/node/328541
//
//  Version: 1.0.0
//  - initial Version
//
//  Todo:
//  - add more levels and structure in a way that complexity raises reasonably
//  - add .-notes 
//  - improve UI for selecting note range
//  - known bug: tempo cannot be changed after training score is created within Musescore by changing the value
//  - add auto transpose into various key's
//  - known bug: Musescore does not create a bass clef when newscore is called with "piano" or "grand-piano"
//
//
//  Copyright (C) 2022 Karsten Spriestersbach
//                Thanks to jeetee for support with tempo changes
//=============================================================================
import QtQuick 2.2
import QtQuick.Controls 2.1 //was QtQuick.Controls 1.1 in first version, 2.1 supports onPressed - event.
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

import MuseScore 3.0

MuseScore {
	menuPath: "Plugins.SightReadingTrainer"
	version: "1.0.6"
	description: qsTr("Creates random notes and rests to train sight reading")
	pluginType: "dialog"
	requiresScore: false
	id: 'pluginId'

	width: 400
	height: 900

	function addRandomNote(noteSet, cursor) { 

		var idx = Math.floor(Math.random() * noteSet.length);
		// console.log("add random Note, idx: " + idx);
		// console.log("add random Note: " + noteSet[idx]);
		cursor.addNote(noteSet[idx]);
		//cursor.next(); do not add a next call here! it will add rests.
	}

	function createNoteSet(minNoteInt, maxNoteInt){
				   //C	D   E   F   G   A   B
		var cdur = [ 0, 2,  4,  5,  7,  9, 11 ];
		var octave = -1;
		var cMajAll = new Array();
		for(var k=0; k < (88-48); k++){
			if(0 == (k % 7)){
				octave++;
			}
			cMajAll[k] = cdur[(k % 7)] + 48 + (octave * 12);
			//console.log("octave: " + octave);
		}
		console.log("cMajAll length: " + cMajAll.length);
		console.log("cMajAll: " + cMajAll);
		
		var noteSet = new Array();
		var start = 0;
		var stop = 0;
		for(var l = 0; l< cMajAll.length; l++){
			if((0 == start) && (minNoteInt <= cMajAll[l])){
				start = l;
			}
			if((0 == stop) && (maxNoteInt <= cMajAll[l])){
				stop = l;
			}
		}
		// console.log("start: " + start);
		// console.log("stop: " + stop);
		
		if(onlyCmajCB.checked){
			console.log("only Cmaj");
			for(var i = 0; i < (stop - start); i++){
				noteSet[i] = cMajAll[i + start];
			}
			
		}else{
			console.log("all notes");
			for(var j = 0; j< (maxNoteInt - minNoteInt); j++){
				noteSet[j] = j + minNoteInt;
			}
		}
		console.log("noteSet: " + noteSet);
		return noteSet;
	}

     
	function findExistingTempoElement(segment)
	{ //look in reverse order, there might be multiple TEMPO_TEXTs attached
		// in that case MuseScore uses the last one in the list
		for (var i = segment.annotations.length; i-- > 0; ) {
			  if (segment.annotations[i].type === Element.TEMPO_TEXT) {
					return (segment.annotations[i]);
			  }
		}
		return undefined; //invalid - no tempo text found
	}
	  
	function setTempo(cursor, tempo){
		
		var tempoElement = findExistingTempoElement(cursor.segment);
		if(undefined == tempoElement){
			console.log("no tempo Element found");
			tempoElement = newElement(Element.TEMPO_TEXT);
			tempoElement.text = /*beatBaseItem.sym +*/'<sym>metNoteQuarterUp</sym>' + ' = ' + tempo;
			tempoElement.visible = true; //visible;
			
			cursor.add(tempoElement); //first add tempoElement then change the actual tempo!!
			console.log("tempo: " + tempo);
			tempoElement.tempo = tempo / 60; //set the "Musescore" Tempo
			//tempoElement.followText = true;//valid in earlier Musescore versions
			tempoElement.tempoFollowText = true;//valid since 3.6, maybe even a little earlier.
		}else{
			console.log("Error: found tempo Element: " + tempoElement);
		}
		return;
	}
	  
	function getFloatFromInput(input)
	{
		var value = input.text;
		if (value == "") {
			  value = input.placeholderText;
		}
		return parseFloat(value);
	}

	function getIntFromInput(input)
	{
		var value = input.text;
		if (value == "") {
			  value = input.placeholderText;
		}
		return parseInt(value);
	}

	function getTempoFromInput(input)
	{
		return getFloatFromInput(input);// / 60;
	}
	
	Settings {
		id: settings
		category: "siteReadingTrainer"
		property alias bpmValue: bpmValue.text
		property alias numMeasures: numMeasures.text
		property alias countInCB: countInCB.checked
		property alias wholeNoteCB: wholeNoteCB.checked
		property alias halfNoteCB: halfNoteCB.checked
		property alias quarterNoteCB: quarterNoteCB.checked
		property alias eightsNoteCB: eightsNoteCB.checked
		property alias sixteenthNoteCB: sixteenthNoteCB.checked
		property alias maxRestsInput: maxRestsInput.text
		property alias wholeRestCB: wholeRestCB.checked
		property alias halfRestCB: halfRestCB.checked
		property alias quarterRestCB: quarterRestCB.checked
		property alias eightsRestCB: eightsRestCB.checked
		property alias sixteenthRestCB: sixteenthRestCB.checked
		property alias onlyCmajCB: onlyCmajCB.checked
		property alias maxNote: maxNote.text
		property alias minNote: minNote.text
		property alias trainingLevel: trainingLevel.currentIndex
		property alias trainingLevelLabel: trainingLevelLabel.text

	}


    onRun: {
		if ((mscoreMajorVersion == 3) && (mscoreMinorVersion == 0) && (mscoreUpdateVersion < 5)) {
			console.log(qsTr("Unsupported MuseScore version.\nTempoChanges needs v3.0.5 or above.\n"));
            pluginId.parent.Window.window.close();
            return;
		}
	}
	
	function resetToDefaultConfig(){
		bpmValue.text = "50";
		numMeasures.text = "4";
		countInCB.checked = true;
		wholeNoteCB.checked = true;
		halfNoteCB.checked = true;
		quarterNoteCB.checked = true;
		eightsNoteCB.checked = true;
		sixteenthNoteCB.checked = true;
		maxRestsInput.text = "1";
		wholeRestCB.checked = true;
		halfRestCB.checked = true;
		quarterRestCB.checked = true;
		eightsRestCB.checked = true;
		sixteenthRestCB.checked = true;
		onlyCmajCB.checked = true;
		maxNote.text = "73";
		minNote.text = "48";
		trainingLevel.currentIndex = 0;
	}
	
	function resetTrainingLevel(){
		if(0 != trainingLevel.currentIndex){
			trainingLevelLabel.text = "Training Level: Last level: " + (trainingLevel.currentIndex + 1);
		}
		trainingLevel.currentIndex = 0;
	}

	
	function setTrainingLevel(index){
		console.log("setTrainingLevel: " + index);
		var C4 = 60;
		var D4 = 62;
		var E4 = 64;
		var F4 = 65;
		var G4 = 67;
		var A4 = 69;
		var B4 = 71;
		var octave = 12;
		
		if(0 == index){
			
		} else if(1 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+D4;
			minNote.text = ""+C4;

		} else if(2 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+E4;
			minNote.text = ""+C4;

		} else if(3 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+F4;
			minNote.text = ""+C4;

		} else if(4 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+G4;
			minNote.text = ""+C4;

		} else if(5 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+A4;
			minNote.text = ""+C4;

		} else if(6 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+B4;
			minNote.text = ""+C4;

		} else if(7 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = ""+(C4 + octave);
			minNote.text = ""+C4;

		} else if(8 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (D4 + octave);
			minNote.text = "" + C4;

		} else if(9 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (E4 + octave);
			minNote.text = "" + C4;

		} else if(10 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (F4 + octave);
			minNote.text = "" + C4;

		} else if(11 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (G4 + octave);
			minNote.text = "" + C4;

		} else if(12 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (A4 + octave);
			minNote.text = "" + C4;

		} else if(13 == index){
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = true;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = false;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = false;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + (C4 + octave + octave);
			minNote.text = "" + C4;
		} else if(14 == index){
			//rest training...
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = false;
			halfNoteCB.checked = false;
			quarterNoteCB.checked = true;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "2";
			wholeRestCB.checked = false;
			halfRestCB.checked = false;
			quarterRestCB.checked = true;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + D4;
			minNote.text = "" + C4;
		} else if(15 == index){
			//rest training...
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = false;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = true;
			eightsNoteCB.checked = false;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = true;
			quarterRestCB.checked = true;
			eightsRestCB.checked = false;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + D4;
			minNote.text = "" + C4;
		} else if(16 == index){
			//rest training...
			bpmValue.text = "50";
			numMeasures.text = "16";
			countInCB.checked = true;
			wholeNoteCB.checked = false;
			halfNoteCB.checked = true;
			quarterNoteCB.checked = true;
			eightsNoteCB.checked = true;
			sixteenthNoteCB.checked = false;
			maxRestsInput.text = "1";
			wholeRestCB.checked = false;
			halfRestCB.checked = true;
			quarterRestCB.checked = true;
			eightsRestCB.checked = true;
			sixteenthRestCB.checked = false;
			onlyCmajCB.checked = true;
			maxNote.text = "" + D4;
			minNote.text = "" + C4;
		} else if(17 == index){
			// bpmValue.text = "50";
			// numMeasures.text = "16";
			// countInCB.checked = true;
			// wholeNoteCB.checked = false;
			// halfNoteCB.checked = false;
			// quarterNoteCB.checked = true;
			// eightsNoteCB.checked = false;
			// sixteenthNoteCB.checked = false;
			// maxRestsInput.text = "1";
			// wholeRestCB.checked = false;
			// halfRestCB.checked = false;
			// quarterRestCB.checked = true;
			// eightsRestCB.checked = false;
			// sixteenthRestCB.checked = false;
			// onlyCmajCB.checked = true;
			// maxNote.text = "" + D4;
			// minNote.text = "" + C4;
		} else if(18 == index){
			// bpmValue.text = "50";
			// numMeasures.text = "16";
			// countInCB.checked = true;
			// wholeNoteCB.checked = false;
			// halfNoteCB.checked = true;
			// quarterNoteCB.checked = false;
			// eightsNoteCB.checked = false;
			// sixteenthNoteCB.checked = false;
			// maxRestsInput.text = "1";
			// wholeRestCB.checked = false;
			// halfRestCB.checked = false;
			// quarterRestCB.checked = false;
			// eightsRestCB.checked = false;
			// sixteenthRestCB.checked = false;
			// onlyCmajCB.checked = true;
			// maxNote.text = "" + D4;
			// minNote.text = "" + C4;
		} else if(19 == index){
			// bpmValue.text = "50";
			// numMeasures.text = "16";
			// countInCB.checked = true;
			// wholeNoteCB.checked = false;
			// halfNoteCB.checked = true;
			// quarterNoteCB.checked = true;
			// eightsNoteCB.checked = true;
			// sixteenthNoteCB.checked = false;
			// maxRestsInput.text = "1";
			// wholeRestCB.checked = false;
			// halfRestCB.checked = false;
			// quarterRestCB.checked = false;
			// eightsRestCB.checked = false;
			// sixteenthRestCB.checked = false;
			// onlyCmajCB.checked = true;
			// maxNote.text = "" + D4;
			// minNote.text = "" + C4;
		} else if(20 == index){
			// bpmValue.text = "50";
			// numMeasures.text = "16";
			// countInCB.checked = true;
			// wholeNoteCB.checked = false;
			// halfNoteCB.checked = true;
			// quarterNoteCB.checked = true;
			// eightsNoteCB.checked = true;
			// sixteenthNoteCB.checked = false;
			// maxRestsInput.text = "1";
			// wholeRestCB.checked = false;
			// halfRestCB.checked = false;
			// quarterRestCB.checked = false;
			// eightsRestCB.checked = false;
			// sixteenthRestCB.checked = false;
			// onlyCmajCB.checked = true;
			// maxNote.text = "" + D4;
			// minNote.text = "" + C4;
		} else console.log("Error: Invalid index in Training Level");
	}

	// Config Info will be written instead of cmposer at the top of the score.
	function createConfigInfo(){
		var str = "bpm: " + bpmValue.text;
		str += "\n measures: " + numMeasures.text; 
		str += "\n countIn: " + countInCB.checked;
		str += "\n WholeNote: " + wholeNoteCB.checked;
		str += "\n halfNote: " + halfNoteCB.checked;
		str += "\n quarterNote: " + quarterNoteCB.checked;
		str += "\n eightsNote: " + eightsNoteCB.checked;
		str += "\n sixteenthNote: " + sixteenthNoteCB.checked;
		str += "\n maxRestsInput: " + maxRestsInput.text;
		str += "\n wholeRest: " + wholeRestCB.checked;
		str += "\n halfRest: " + halfRestCB.checked;
		str += "\n quarterRest: " + quarterRestCB.checked;
		str += "\n eightsRest: " + eightsRestCB.checked;
		str += "\n sixteenthRest: " + sixteenthRestCB.checked;
		str += "\n onlyCmaj: " + onlyCmajCB.checked;
		str += "\n maxNote: " + maxNote.text;
		str += "\n minNote: " + minNote.text;
		return str; 
	}

	//make sure it is always: min_const < min < max < max_const
	function validateMinMaxNote(){
		var maxNoteInt = getIntFromInput(maxNote);
		// console.log("onTextChanged:maxNoteInt: " + maxNoteInt);
		var minNoteInt = getIntFromInput(minNote);
		if(48 > minNoteInt) 
		{
			minNoteInt = 48;
			minNote.text = "" + minNoteInt;
			// console.log("onTextChanged2:minNoteInt: " + minNoteInt);
		}
		if(88 < maxNoteInt) 
		{
			maxNoteInt = 88;
			maxNote.text = "" + maxNoteInt;
			// console.log("onTextChanged2:maxNoteInt: " + maxNoteInt);
		}
		if(minNoteInt >= maxNoteInt){
			minNoteInt = maxNoteInt - 1;
		}
		maxNote.text = "" + maxNoteInt;
		minNote.text = "" + minNoteInt;
	}
	
	function applySiteReadingTrainer(){
		var tempo		= 50; // bpm
		var measures    = 4;  //in 4/4 default time signature, 1 measure to count in
		var numerator   = 4;  //const!
		var denominator = 4;  //const!
		var countIn		= true;
		// --- end config ---
		
		var strCountIn = "yes";

        if (countInCB.checked){
			countIn = true;
		}else{
			countIn = false;
		}
		tempo = getTempoFromInput(bpmValue);
		measures = getFloatFromInput(numMeasures);
		
		if(!countIn) strCountIn = "no";
		console.log("count In: " + countIn);
		if(countIn){
			measures++;
		}

		//var score = newScore("Random.mscz", "piano", measures);
		var score = newScore("Random.mscz", "x", measures); //creates a crash if eights rest are applied. don't know why
		//var score = newScore("Random.mscz", "grand-piano", measures);
		//var score = newScore("Random.mscz", "violin", measures);
		
		score.startCmd();
		//trying to add a bass clef "F" but it does not work this way :-(
		//score.appendPart("grand-piano");
		//score.appendPartByMusicXmlId("grand-piano");

		score.addText("title", "Sight Reading Trainer");
		var trainingMeasures = measures; 
		if(countIn){
			trainingMeasures--;
		}
		//score.addText("subtitle", "Time Signature: " + numerator + "/" + denominator +", Measures: " + trainingMeasures + ", Count in: " + strCountIn);
		score.addText("composer", createConfigInfo());

		var cursor = score.newCursor();
		cursor.track = 0;
		cursor.rewind(0);
		
		// write the time like 4/4 or 3/4 to the score direct after violin clef
		var ts = newElement(Element.TIMESIG);
		ts.timesig = fraction(numerator, denominator);
		cursor.add(ts);
		
		setTempo(cursor, tempo);
		
		var realMeasures = Math.ceil(measures * denominator / numerator);
		console.log("realMeasures: " + realMeasures);
		var notes = realMeasures * 16; //number of 1/16th notes, always the highest possible value allowed
		
		if(countIn){		
			console.log("add count in measure");
			cursor.setDuration(1, 1);
			cursor.addRest();
			notes = notes - 16;
		}
		console.log("Number of sixteenth Notes to add: " + notes);
		
		validateMinMaxNote();
		var maxNoteInt = getIntFromInput(maxNote);
		console.log("maxNoteInt: " + maxNoteInt);
		var minNoteInt = getIntFromInput(minNote);
		console.log("minNoteInt: " + minNoteInt);

		var noteSet = createNoteSet(minNoteInt, maxNoteInt);
			
		var measureIndex = realMeasures;
		while(0 < measureIndex){
			console.log("measureIndex/realMeasures: " + measureIndex + "/" + realMeasures);
			measureIndex--;
			var notesIndex = 16; //max allowed resolution
			
			//allow max number of rests in one measure to avoid measures which only contain rests...
			var maxRestsInAMeasure = getFloatFromInput(maxRestsInput);
			var restCount = 1;
			//if true then the last note added was a rest. we don't want two subsequent rests
			// independent from value of maxRestInAMeasure.
			var noSubsequentRests = false;
			
			while(0 < notesIndex){ //max notes are sixteenth notes!!
				var rand = Math.floor((Math.random() * 10) + 1);
				//console.log("random duration: " + rand);
				// whole note
				if(wholeNoteCB.checked && (16 == notesIndex) && (1 == rand)){
					console.log("add whole note");
					cursor.setDuration(1, 1);
					addRandomNote(noteSet, cursor);
					noSubsequentRests = false;//fine to add a rest even though this was a whole note so there is no space
					notesIndex = notesIndex - 16;
					break;
				}
				// whole rests
				else if(wholeRestCB.checked && (16 == notesIndex) && (2 == rand)){
					if(maxRestsInAMeasure < restCount){
						continue;
					}
					if(noSubsequentRests) {
						continue;
					}
					restCount++;
					console.log("add whole rest");
					cursor.setDuration(1, 1);
					cursor.addRest();
					noSubsequentRests = true;//next add must be a note
					notesIndex = notesIndex - 16;
					break;
				}
				// half note
				else if(halfNoteCB.checked && (8 <= notesIndex) && (3 == rand)){
					console.log("add half note");
					//cursor.setDuration(3, 4);
					cursor.setDuration(1, 2);
					addRandomNote(noteSet, cursor);
					noSubsequentRests = false;//next add might be a rest or note
					notesIndex = notesIndex - 8;
				}
				// half rests
				else if((halfRestCB.checked && 8 <= notesIndex) && (4 == rand)){
					if(maxRestsInAMeasure < restCount){
						continue;
					}
					if(noSubsequentRests) {
						continue;
					}
					restCount++;
					console.log("add half rest");
					cursor.setDuration(1, 2);
					cursor.addRest();
					noSubsequentRests = true;//next add must be a note
					notesIndex = notesIndex - 8;
				}
				// quarter note
				else if(quarterNoteCB.checked && (4 <= notesIndex) && (5 == rand)){
					console.log("add quarter note");
					cursor.setDuration(1, 4);
					addRandomNote(noteSet, cursor);
					noSubsequentRests = false;//next add might be a rest or note
					notesIndex = notesIndex - 4;
				}
				// quarter rests
				else if(quarterRestCB.checked && (4 <= notesIndex) && (6 == rand)){
					if(maxRestsInAMeasure < restCount){
						continue;
					}
					if(noSubsequentRests) {
						continue;
					}
					restCount++;
					console.log("add quarter rest");
					cursor.setDuration(1, 4);
					cursor.addRest();
					noSubsequentRests = true;//next add must be a note
					notesIndex = notesIndex - 4;
				}
				// eights note
				else if(eightsNoteCB.checked && (2 <= notesIndex) && (7 == rand)){
					console.log("add eights note");
					cursor.setDuration(1, 8);
					addRandomNote(noteSet, cursor);
					noSubsequentRests = false;//next add might be a rest or note
					notesIndex = notesIndex - 2;
				}
				// eights rests
				else if(eightsRestCB.checked && (2 <= notesIndex) && (8 == rand)){
					if(maxRestsInAMeasure < restCount){
						continue;
					}
					if(noSubsequentRests) {
						continue;
					}
					restCount++;
					console.log("add eights rest");
					cursor.setDuration(1, 8);
					cursor.addRest();
					noSubsequentRests = true;//next add must be a note
					notesIndex = notesIndex - 2;
				}
				// sixteenth note
				else if(sixteenthNoteCB.checked && (1 <= notesIndex) && (9 == rand)){
					console.log("add sixteenth note");
					cursor.setDuration(1, 16);
					addRandomNote(noteSet, cursor);
					noSubsequentRests = false;//next add might be a rest or note
					notesIndex--;
				}
				// sixteenth rest
				else if(sixteenthRestCB.checked && (1 <= notesIndex) && (10 == rand)){
					if(maxRestsInAMeasure < restCount){
						continue;
					}
					if(noSubsequentRests) {
						continue;
					}
					restCount++;
					console.log("add sixteenth rest");
					cursor.setDuration(1, 16);
					cursor.addRest();
					noSubsequentRests = true;//next add must be a note
					notesIndex--;
				}
			}
		}			

		console.log("all notes set, end script");
		//Qt.quit();
		score.endCmd(false);
	
	}
	

	
	GridLayout {
            id: 'mainLayout'
            anchors.fill: parent
            anchors.margins: 10
            columns: 2
			rows: 21
            focus: true
			
            // Canvas {
                  // id: canvas
                  //Layout.rowSpan: 2
                  // Layout.minimumWidth: 102
                  // Layout.minimumHeight: 102
                  // Layout.fillWidth: true
                  // Layout.fillHeight: true
                  
                  // onPaint: {
                        // var w = canvas.width;
                        // var h = canvas.height;

						// console.log("bpmValue: " + bpmValue);
						// console.log("getFloatFromInput(bpmValue): " + getFloatFromInput(bpmValue));
                        // canvasBPM.text = getFloatFromInput(bpmValue);
                        // canvasNumMeasures.text = getFloatFromInput(numMeasures);

						// console.log("onPaint");

						// var maxNoteInt = getIntFromInput(maxNote);
						// console.log("onPaint1:maxNoteInt: " + maxNoteInt);
						// var minNoteInt = getIntFromInput(minNote);
						// console.log("onPaint1:minNoteInt: " + minNoteInt);
						// if(0 > minNoteInt) 
						// {
							// minNoteInt = 0;
							// minNote.text = "" + minNoteInt;
							// console.log("onPaint2:minNoteInt: " + minNoteInt);
						// }
						// if(1 > maxNoteInt) 
						// {
							// maxNoteInt = 1;
							// maxNote.text = "" + maxNoteInt;
							// console.log("onPaint2:maxNoteInt: " + maxNoteInt);
						// }
						// if(minNoteInt > maxNoteInt){
							// minNoteInt = maxNoteInt - 1;
						// }
                  // }
				  
                  // Label {
                        // id: canvasBPM
                        // color: '#d8d8d8'
                  // }
                  // Label {
                        // id: canvasNumMeasures
                        // color: '#d8d8d8'
                  // }
				  
            // } //end of Canvas

            Label {
                  text: qsTr("Version: " + version)
				  Layout.columnSpan: 2
            }
            Label {
                  text: qsTr("BPM:")
            }
            TextField {
                id: bpmValue
                placeholderText: '50'
                validator: DoubleValidator { bottom: 1;/* top: 512;*/ decimals: 1; notation: DoubleValidator.StandardNotation; }
                implicitHeight: 28
                // onTextChanged: { 
					// //canvas.requestPaint(); 
				// }
				onEditingFinished: {
					// console.log("onEditingFinished, bpmValue");
					resetTrainingLevel();
				}
				onPressed: {
					console.log("onPressed, bpmValue");
					resetTrainingLevel();
				}

				  
            }
            Label {
                  text: qsTr("Num Measures:")
            }
            TextField {
                id: numMeasures
                placeholderText: '16'
                validator: DoubleValidator { bottom: 1;/* top: 512;*/ decimals: 1; notation: DoubleValidator.StandardNotation; }
                implicitHeight: 28
                // onTextChanged: { 
					// //canvas.requestPaint(); 
				// }
				onEditingFinished: {
					// console.log("onEditingFinished, numMeasures");
					resetTrainingLevel();
				}
				onPressed: {
					console.log("onPressed, numMeasures");
					resetTrainingLevel();
				}

            }
			
			CheckBox {
				id: countInCB
				text: "Add count in measure"
				Layout.columnSpan: 2
				checked: true
				//exclusiveGroup: exclusiveGroup
				onClicked: { 
					//console.log("onClicked: countInCB"); 
					resetTrainingLevel();
				}
			}
			
            Label {
                  text: qsTr("Notes:")
				  Layout.columnSpan: 2
            }
			CheckBox {
				id: wholeNoteCB
				text: "whole"
				checked: true
				onClicked: { 
					//console.log("onClicked: wholeNoteCB"); 
					resetTrainingLevel();
				}
			}
			// ComboBox {
				// id: wholeNoteComb
				// //Layout.columnSpan: 2
				// currentIndex: 0
				// width: parent.width
				// //implicitHeight: 50
				// implicitWidth: 380
				// model: ["--whole--",
				// "whole", 
				// "whole + ."]
				// onCurrentIndexChanged: {
					// //trainingLevelLabel.text = "Training Level: Last level: " + (currentIndex+1)
					// resetTrainingLevel();
				// }
			// }
			
			CheckBox {
				id: halfNoteCB
				text: "half"
				checked: true
				onClicked: { 
					//console.log("onClicked: halfNoteCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: quarterNoteCB
				text: "quarter"
				checked: true
				onClicked: { 
					//console.log("onClicked: quarterNoteCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: eightsNoteCB
				text: "eights"
				checked: true
				onClicked: { 
					//console.log("onClicked: eightsNoteCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: sixteenthNoteCB
				text: "sixteenth"
				checked: true
				onClicked: { 
					//console.log("onClicked: sixteenthNoteCB"); 
					resetTrainingLevel();
				}
			}
			// CheckBox {
				// id: dotNoteCB
				// text: "'.'(dot) notes"
				// checked: true
				// onClicked: { 
					// //console.log("onClicked: sixteenthRestCB"); 
					// resetTrainingLevel();
				// }
			// }

		
            Label {
                  text: qsTr("Rests:")
				  Layout.columnSpan: 2
            }
			Label {
                  text: qsTr("Max Rests per Measure:")
            }
            TextField {
                id: maxRestsInput
                placeholderText: '1'
                validator: DoubleValidator { bottom: 1;/* top: 512;*/ decimals: 1; notation: DoubleValidator.StandardNotation; }
                implicitHeight: 28
                //onTextChanged: { canvas.requestPaint(); }
				onEditingFinished: {
					// console.log("onEditingFinished, maxRestsInput");
					resetTrainingLevel();
				}
				onPressed: {
					console.log("onPressed, maxRestsInput");
					resetTrainingLevel();
				}
				
            }
			CheckBox {
				id: wholeRestCB
				text: "whole"
				checked: true
				onClicked: { 
					//console.log("onClicked: wholeRestCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: halfRestCB
				text: "half"
				checked: true
				onClicked: { 
					//console.log("onClicked: halfRestCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: quarterRestCB
				text: "quarter"
				checked: true
				onClicked: { 
					//console.log("onClicked: quarterRestCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: eightsRestCB
				text: "eights"
				checked: true
				onClicked: { 
					//console.log("onClicked: eightsRestCB"); 
					resetTrainingLevel();
				}
			}
			CheckBox {
				id: sixteenthRestCB
				text: "sixteenth"
				checked: true
				onClicked: { 
					//console.log("onClicked: sixteenthRestCB"); 
					resetTrainingLevel();
				}
			}
			// CheckBox {
				// id: dotRestCB
				// text: "'.'(dot) rests"
				// checked: true
				// onClicked: { 
					// //console.log("onClicked: sixteenthRestCB"); 
					// resetTrainingLevel();
				// }
			// }
 
			// CheckBox {
				// id: augmentedDot
				// text: "dot <.>"
				// checked: true
				// //exclusiveGroup: exclusiveGroup
				// onClicked: { 
					//console.log("onClicked: sixteenthRestCB"); 
					// resetTrainingLevel();
				// }
			// }
			
			Label {
                  text: qsTr("Random Notes Set:")
				  Layout.columnSpan: 2
            }
			Label {
                  text: qsTr("(Note: min <= max!!, 47 < min < max < 89)")
				  Layout.columnSpan: 2
            }

			CheckBox {
				id: onlyCmajCB
				text: "Only Cmaj"
				Layout.columnSpan: 2
				checked: true
				//exclusiveGroup: exclusiveGroup
				onClicked: { 
					//console.log("onClicked: onlyCmajCB"); 
					resetTrainingLevel();
				}
			}

			Label {
                  text: qsTr("Max Note (C5=73):")
            }
            TextField {
				id: maxNote
				placeholderText: '72'
				validator: IntValidator { bottom: 49; top: 88;}
				implicitHeight: 28
				//                  onTextChanged: { canvas.requestPaint(); }
				// onTextChanged: { 
					// console.log("onTextChanged: maxNote");
					// resetTrainingLevel();
				// }
				onEditingFinished: {
					// console.log("onEditingFinished, maxNote");
					//resetTrainingLevel();
					validateMinMaxNote();
				}
				onPressed: {
					console.log("onPressed, maxNote");
					resetTrainingLevel();
				}
            }

			Label {
                  text: qsTr("Min Note(C3=48):")
            }
            TextField {
				id: minNote
				placeholderText: '48'
				validator: IntValidator { bottom: 48; top: 87;}
				implicitHeight: 28
				// onTextChanged: { 
					// console.log("onTextChanged: minNote");
					// resetTrainingLevel();
				// }
				onEditingFinished: {
					// console.log("onEditingFinished, minNote");
					//resetTrainingLevel();
					validateMinMaxNote();
				}
				onPressed: {
					console.log("onPressed, minNote");
					resetTrainingLevel();
				}
            }
			
			Label {
                  id: trainingLevelLabel
				  text: qsTr("Training Level: ")
				  Layout.columnSpan: 2
            }
			
			ComboBox {
				id: trainingLevel
				Layout.columnSpan: 2
				currentIndex: 0
				width: parent.width
				//implicitHeight: 50
				implicitWidth: 380
				model: ["1: user defined",
				"2: just C4, whole + half note", 
				"3: C4, D4, whole + half note", 
				"4: C4 - E4, whole + half note", 
				"5: C4 - F4, whole + half note", 
				"6: C4 - G4, whole + half note", 
				"7: C4 - A4, whole + half note", 
				"8: C4 - B4, whole + half note", 
				"9: C4 - C5, whole + half note", 
				"10: C4 - D5, whole + half note", 
				"11: C4 - E5, whole + half note", 
				"12: C4 - F5, whole + half note", 
				"13: C4 - G5, whole + half note", 
				"14: C4 - A5, whole + half note", 
				"15: C4, 4th note, 4th rest", 
				"16: C4, half/4th note, half/4th rest", 
				"17: C4, half/4th/8th note, half/4th/8th rest", 
				"18: undefined", 
				"19: undefined", 
				"20: undefined"]
				onCurrentIndexChanged: {
					//trainingLevelLabel.text = "Training Level: Last level: " + (currentIndex+1)
					setTrainingLevel(currentIndex);
				}
			}
			
            // Button {
                  // id: resetButton
                  // Layout.columnSpan: 2
                  // text: qsTranslate("PrefsDialogBase", "Reset to Default")
                  // onClicked: {
                        // resetTrainingLevel();
						// resetToDefaultConfig();
                  // }
            // }
            Button {
                  id: applyButton
                  //Layout.columnSpan: 2
                  text: qsTranslate("PrefsDialogBase", "Create Training Sheet")
                  onClicked: {
                        applySiteReadingTrainer();
                        pluginId.parent.Window.window.close();
						Qt.quit();
                  }
            }
            Button {
                  id: cancelButton
                  //Layout.columnSpan: 2
                  text: qsTranslate("PrefsDialogBase", "Exit")
                  onClicked: {
                        pluginId.parent.Window.window.close();
						Qt.quit();
                  }
            }
      }

      Keys.onEscapePressed: {
            pluginId.parent.Window.window.close();
			Qt.quit();
      }
      Keys.onReturnPressed: {
            applySiteReadingTrainer();
            pluginId.parent.Window.window.close();
			Qt.quit();
      }
      Keys.onEnterPressed: {
            applySiteReadingTrainer();
            pluginId.parent.Window.window.close();
			Qt.quit();
      }
	  // Keys.onPressed: {
		// console.log("event.key: " + event.key);
        // if (event.key == Qt.Key_Left) {
            // console.log("move left");
            // event.accepted = true;
        // }
	  // }
}
