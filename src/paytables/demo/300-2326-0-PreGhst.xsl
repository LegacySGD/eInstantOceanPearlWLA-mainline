<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioWinNums = getWinNumsData(scenario);
						var scenarioYourNums = getYourNumsData(scenario);
						var scenarioBonusGame = getBonusGameData(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(','); 

						////////////////////
						// Parse scenario //
						////////////////////

						const bonusSymb = 'Z';

						var arrScenarioYourNums = [];
						var arrYourNum          = [];
						var arrYourNums         = [];
						var arrYourNumsPerMulti = [];
						var doBonusGame         = false;
						var doWins              = false;
						var objYourNum          = {};
						var arrWins             = [];
						var arrWinsPerMulti     = [];

						for (var multiIndex = 0; multiIndex < scenarioYourNums.length; multiIndex++)
						{
							arrScenarioYourNums = scenarioYourNums[multiIndex].split(",");

							arrYourNumsPerMulti = [];
							arrWinsPerMulti     = [];

							for (var YNIndex = 0; YNIndex < arrScenarioYourNums.length; YNIndex++)
							{
								objYourNum = {sYourNum: '', sPrize: '', bMatch: false};

								if (arrScenarioYourNums[YNIndex] == bonusSymb)
								{
									objYourNum.sPrize = arrScenarioYourNums[YNIndex];

									doBonusGame = true;
								}
								else
								{
									arrYourNum = arrScenarioYourNums[YNIndex].split(":");

									objYourNum.sYourNum = arrYourNum[0];
									objYourNum.sPrize   = arrYourNum[1];

									if (scenarioWinNums.indexOf(arrYourNum[0]) != -1)
									{
										objYourNum.bMatch = true;
										doWins = true;

										arrWinsPerMulti.push(YNIndex);
									}
								}

								arrYourNumsPerMulti.push(objYourNum);
							}

							arrYourNums.push(arrYourNumsPerMulti);
							arrWins.push(arrWinsPerMulti);
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////
						
						const doBonusCell    = true;
						const doTitleCell    = true;
						const symbMGFeatures = 'mz';

						const cellHeight   = 24;
						const cellMargin   = 1;
						const cellTextY    = 15;
						const cellWidth    = 96;
						const cellWidthKey = 24;

						const colourBlack  = '#000000';
						const colourBlue   = '#99ccff';
						const colourGreen  = '#ccff99';
						const colourLilac  = '#ccccff';
						const colourOrange = '#ffcc99';
						const colourRed    = '#ff9999';
						const colourWhite  = '#ffffff';
						const colourYellow = '#ffff99';

						const MGColours = [colourGreen, colourOrange];

						var r = [];

						var boxColourStr = '';
						var canvasIdStr  = '';
						var elementStr   = '';
						var symbMG       = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_iBoxWidth, A_strBoxColour, A_strText, A_doMGBonus, A_doTitle)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = A_iBoxWidth + 2 * cellMargin;
							var canvasHeight = (A_doMGBonus) ? 2 * (cellHeight + cellMargin) : cellHeight + 2 * cellMargin;
							var boxHeight    = (A_doMGBonus) ? 2 * cellHeight : cellHeight;
							var textColour   = (A_doTitle) ? colourWhite : colourBlack;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + boxHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxWidth - 2).toString() + ', ' + (boxHeight - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + cellMargin).toString() + ', ' + (boxHeight / 2 + cellMargin + 2).toString() + ');');

							r.push('</script>');
						}

						//////////////////
						// Features Key //
						//////////////////

						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleFeaturesKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var featureIndex = 0; featureIndex < symbMGFeatures.length; featureIndex++)
						{
							symbMG       = symbMGFeatures[featureIndex];
							canvasIdStr  = 'cvsKeySymb' + symbMG;
							elementStr   = 'eleKeySymb' + symbMG;
							boxColourStr = MGColours[featureIndex];
							symbDesc     = 'symb' + symbMG.toUpperCase();

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, cellWidthKey, boxColourStr, '#', !doBonusCell, !doTitleCell);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						var cellStr = '';

						function showYourNum(A_strCanvasId, A_strCanvasElement, A_objYourNum)
						{
							var gridCanvasWidth  = cellWidth + 2 * cellMargin;
							var gridCanvasHeight = 2 * (cellHeight + cellMargin);

							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellY        = 0;
							var isWinner     = A_objYourNum.bMatch;

							boxColourStr = (isWinner) ? colourGreen : colourWhite;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var YNPartIndex = 0; YNPartIndex < 2; YNPartIndex++)
							{
								cellY   = YNPartIndex * cellHeight;
								cellStr = (YNPartIndex == 0) ? A_objYourNum.sYourNum : convertedPrizeValues[getPrizeNameIndex(prizeNames, A_objYourNum.sPrize)];

								r.push(canvasCtxStr + '.font = "bold 14px Arial";');
								r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellWidth.toString() + ', ' + cellHeight.toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
								r.push(canvasCtxStr + '.fillText("' + cellStr + '", ' + (cellWidth / 2 + cellMargin).toString() + ', ' + (cellY + cellTextY).toString() + ');');
							}

							r.push('</script>');
						}

						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						/////////////////
						// Win Numbers //
						/////////////////

						r.push('<tr class="tablebody">');

						canvasIdStr = 'cvsTitleWinNum';
						elementStr  = 'eleTitleWinNum';
						cellStr     = getTranslationByName("titleWinNums", translations);

						r.push('<td colspan="5">');

						showSymb(canvasIdStr, elementStr, cellWidth * 3, colourBlack, cellStr, !doBonusCell, doTitleCell);

						r.push('</td>');
						r.push('</tr>');
						r.push('<tr class="tablebody">');

						for (var WNIndex = 0; WNIndex < scenarioWinNums.length; WNIndex++)
						{
							canvasIdStr = 'cvsWinNum' + WNIndex.toString();
							elementStr  = 'eleWinNum' + WNIndex.toString();
							cellStr     = scenarioWinNums[WNIndex];

							r.push('<td>');

							showSymb(canvasIdStr, elementStr, cellWidthKey * 3, colourWhite, cellStr, !doBonusCell, !doTitleCell);

							r.push('</td>');
						}

						r.push('</tr>');
						r.push('</table>');

						//////////////////
						// Your Numbers //
						//////////////////

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						for (var YNMultiIndex = 0; YNMultiIndex < arrYourNums.length; YNMultiIndex++)
						{
							r.push('<tr><td>&nbsp;</td></tr>');

							r.push('<tr class="tablebody">');

							canvasIdStr  = 'cvsTitleYourNum' + YNMultiIndex.toString();
							elementStr   = 'eleTitleYourNum' + YNMultiIndex.toString();
							cellStr      = getTranslationByName("titleYourNums", translations) + ' x' + (YNMultiIndex+1).toString();

							r.push('<td colspan="4">');

							showSymb(canvasIdStr, elementStr, cellWidth * 3, colourBlack, cellStr, !doBonusCell, doTitleCell);

							r.push('</td>');

							for (var YNMultiCellIndex = 0; YNMultiCellIndex < arrYourNums[YNMultiIndex].length; YNMultiCellIndex++)
							{
								if (YNMultiCellIndex % 4 == 0)
								{
									r.push('</tr>');
									r.push('<tr class="tablebody">');
								}

								canvasIdStr = 'cvsYourNum' + YNMultiIndex.toString() + '_' + YNMultiCellIndex.toString();
								elementStr  = 'eleYourNum' + YNMultiIndex.toString() + '_' + YNMultiCellIndex.toString();

								r.push('<td>');

								if (arrYourNums[YNMultiIndex][YNMultiCellIndex].sPrize == bonusSymb)
								{
									showSymb(canvasIdStr, elementStr, cellWidth, colourOrange, getTranslationByName("yourNumBonus", translations), doBonusCell, !doTitleCell);
								}
								else
								{
									showYourNum(canvasIdStr, elementStr, arrYourNums[YNMultiIndex][YNMultiCellIndex]);
								}

								r.push('</td>');
							}

							r.push('</tr>');
						}

						r.push('</table>');

						////////////////////
						// Main Game Wins //
						////////////////////

						function getMultipliedPrize(A_strPrizeDesc, A_iMulti)
						{
							var bCurrSymbAtFront = false;
							var strCurrSymb      = '';
							var strDecSymb       = '';
							var strThouSymb      = '';

							function getPrizeInCents(AA_strPrize)
							{
								var strPrizeWithoutCurrency = AA_strPrize.replace(new RegExp('[^0-9., ]', 'g'), '');
								var iPos 					= AA_strPrize.indexOf(strPrizeWithoutCurrency);
								var iCurrSymbLength 		= AA_strPrize.length - strPrizeWithoutCurrency.length;
								var strPrizeWithoutDigits   = strPrizeWithoutCurrency.replace(new RegExp('[0-9]', 'g'), '');

								strDecSymb 		 = strPrizeWithoutCurrency.substr(-3,1);									
								bCurrSymbAtFront = (iPos != 0);									
								strCurrSymb 	 = (bCurrSymbAtFront) ? AA_strPrize.substr(0,iCurrSymbLength) : AA_strPrize.substr(-iCurrSymbLength);
								strThouSymb      = (strPrizeWithoutDigits.length > 1) ? strPrizeWithoutDigits[0] : strThouSymb;

								return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
							}

							function getCentsInCurr(AA_iPrize)
							{
								var strValue = AA_iPrize.toString();

								strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
								strValue = (strThouSymb != '') ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
								strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

								return strValue;
							}

							var strPrizeAmount = convertedPrizeValues[getPrizeNameIndex(prizeNames, A_strPrizeDesc)];

							var iPrize = getPrizeInCents(strPrizeAmount);
							var iTotal = iPrize * A_iMulti;

							return getCentsInCurr(iTotal);
						}

						if (doWins)
						{
							var iMulti       = 0;
							var strMulti     = '';
							var strPrize     = '';
							var winPrize     = '';
							var yourNumIndex = -1;

							r.push('<br><table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (var winMultiIndex = 0; winMultiIndex < arrWins.length; winMultiIndex++)
							{
								iMulti   = winMultiIndex + 1;
								strMulti = iMulti.toString();

								for (var winIndex = 0; winIndex < arrWins[winMultiIndex].length; winIndex++)
								{
									canvasIdStr  = 'cvsWinMulti' + winMultiIndex.toString() + '_' + winIndex.toString();
									elementStr   = 'eleWinMulti' + winMultiIndex.toString() + '_' + winIndex.toString();
									yourNumIndex = arrWins[winMultiIndex][winIndex];
									cellStr      = arrYourNums[winMultiIndex][yourNumIndex].sYourNum;
									winPrize     = arrYourNums[winMultiIndex][yourNumIndex].sPrize;
									strPrize     = convertedPrizeValues[getPrizeNameIndex(prizeNames, winPrize)];

									r.push('<tr class="tablebody">');
									r.push('<td>' + getTranslationByName("winMatches", translations) + '</td>');
									r.push('<td align="center">');

									showSymb(canvasIdStr, elementStr, cellWidthKey, colourGreen, cellStr, !doBonusCell, !doTitleCell);

									r.push('</td>');
									r.push('<td>' + getTranslationByName("winWithMulti", translations) + ' x' + strMulti + ' : ' + strPrize + ' x ' + strMulti + ' = ' + getMultipliedPrize(winPrize, iMulti) +  '</td>');
									r.push('</tr>');
								}
							}

							r.push('</table>');
						}

						////////////////
						// Bonus Game //
						////////////////

						if (doBonusGame)
						{
							const cellBonusHeight = 48;

							function showBonusPrizes(A_strCanvasId, A_strCanvasElement, A_arrPrizes)
							{
								var gridCanvasWidth  = cellWidth + 2 * cellMargin;
								var gridCanvasHeight = cellBonusHeight + 2 * cellMargin;

								var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
								var cellY        = 0;
								var isMulti1     = false;
								var isMulti2     = false;
								var isPrize      = false;
								var isXtraTurn   = false;
								var cellPrize    = '';
								var bonusText    = '';

								r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
								r.push('<script>');
								r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
								r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
								r.push(canvasCtxStr + '.textAlign = "center";');
								r.push(canvasCtxStr + '.textBaseline = "middle";');

								for (var prizeIndex = 0; prizeIndex < 2; prizeIndex++)
								{
									cellPrize    = A_arrPrizes[prizeIndex];
									isMulti1     = (cellPrize == 'm1');
									isMulti2     = (cellPrize == 'm2');
									isPrize      = (cellPrize != undefined && cellPrize[0] == 'b');
									isXtraTurn   = (cellPrize == 'X');
									boxColourStr = (isMulti1) ? colourBlue : ((isMulti2) ? colourLilac : ((isPrize) ? colourYellow : ((isXtraTurn) ? colourRed : colourWhite)));
									cellY        = prizeIndex * cellHeight;
									bonusText    = (isMulti1) ? getTranslationByName("bonusMulti", translations) + ' +1' : ((isMulti2) ? getTranslationByName("bonusMulti", translations) + ' +2' :
														((isPrize) ? convertedPrizeValues[getPrizeNameIndex(prizeNames, cellPrize)] :
														((isXtraTurn) ? getTranslationByName("bonusExtraTurn", translations) : '')));

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellWidth.toString() + ', ' + cellHeight.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellWidth - 2).toString() + ', ' + (cellHeight - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
									r.push(canvasCtxStr + '.fillText("' + bonusText + '", ' + (cellWidth / 2 + cellMargin).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								}

								r.push('</script>');
							}

							function showBonusTotal(A_arrPrizes, A_iMulti)
							{
								var bCurrSymbAtFront = false;
								var iBonusTotal 	 = 0;
								var iPrize      	 = 0;
								var iPrizeTotal 	 = 0;
								var strCurrSymb      = '';
								var strDecSymb  	 = '';
								var strThouSymb      = '';

								function getPrizeInCents(AA_strPrize)
								{
									var strPrizeWithoutCurrency = AA_strPrize.replace(new RegExp('[^0-9., ]', 'g'), '');
									var iPos 					= AA_strPrize.indexOf(strPrizeWithoutCurrency);
									var iCurrSymbLength 		= AA_strPrize.length - strPrizeWithoutCurrency.length;
									var strPrizeWithoutDigits   = strPrizeWithoutCurrency.replace(new RegExp('[0-9]', 'g'), '');

									strDecSymb 		 = strPrizeWithoutCurrency.substr(-3,1);									
									bCurrSymbAtFront = (iPos != 0);									
									strCurrSymb 	 = (bCurrSymbAtFront) ? AA_strPrize.substr(0,iCurrSymbLength) : AA_strPrize.substr(-iCurrSymbLength);
									strThouSymb      = (strPrizeWithoutDigits.length > 1) ? strPrizeWithoutDigits[0] : strThouSymb;

									return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
								}

								function getCentsInCurr(AA_iPrize)
								{
									var strValue = AA_iPrize.toString();

									strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
									strValue = (strThouSymb != '') ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
									strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

									return strValue;
								}

								for (prizeIndex = 0; prizeIndex < A_arrPrizes.length; prizeIndex++)
								{
									iPrize = getPrizeInCents(A_arrPrizes[prizeIndex]);

									iPrizeTotal += iPrize;
								}

								iBonusTotal = iPrizeTotal * A_iMulti;

								r.push('<br>' + getTranslationByName("bonusPrize", translations) + ' : ' + getCentsInCurr(iPrizeTotal) + ' x ' + A_iMulti.toString() + ' = ' + getCentsInCurr(iBonusTotal));
							}

							r.push('<br><p>' + getTranslationByName("bonusGame", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							//////////////////////
							// Bonus Game Turns //
							//////////////////////

							r.push('<tr class="tablebody">');

							for (var turnIndex = 0; turnIndex < scenarioBonusGame.length; turnIndex++)
							{
								canvasIdStr = 'cvsTitleBonusTurn' + turnIndex.toString();
								elementStr  = 'eleTitleBonusTurn' + turnIndex.toString();
								cellStr     = getTranslationByName("titleBonusTurn", translations) + ' ' + (turnIndex+1).toString();

								r.push('<td>');

								showSymb(canvasIdStr, elementStr, cellWidth, colourBlack, cellStr, !doBonusCell, doTitleCell);

								r.push('</td>');
							}

							r.push('</tr>');
							r.push('<tr class="tablebody">');

							for (var turnIndex = 0; turnIndex < scenarioBonusGame.length; turnIndex++)
							{
								canvasIdStr = 'cvsGridBonus' + turnIndex.toString();
								elementStr  = 'eleGridBonus' + turnIndex.toString();

								r.push('<td>');

								showBonusPrizes(canvasIdStr, elementStr, scenarioBonusGame[turnIndex].split(':'));

								r.push('</td>');
							}

							r.push('</tr>');
							r.push('</table>');

							/////////////////////
							// Bonus Game Wins //
							/////////////////////

							var bonusTurnData  = [];
							var bonusPrizeData = '';
							var bonusMultiQty  = 1;
							var bonusPrizes    = [];

							for (var turnIndex = 0; turnIndex < scenarioBonusGame.length; turnIndex++)
							{
								bonusTurnData = scenarioBonusGame[turnIndex].split(':');

								for (var prizeIndex = 0; prizeIndex < bonusTurnData.length; prizeIndex++)
								{
									bonusPrizeData = bonusTurnData[prizeIndex];

									if (bonusPrizeData[0] == 'm')
									{
										bonusMultiQty += parseInt(bonusPrizeData[1]);
									}
									else if (bonusPrizeData[0] == 'b')
									{
										bonusPrizes.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusPrizeData)]);
									}
								}
							}

							showBonusTotal(bonusPrizes, bonusMultiQty);
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getWinNumsData(scenario)
					{
						return scenario.split("|")[0].split(",");
					}

					function getYourNumsData(scenario)
					{
						return scenario.split("|").slice(1,4);
					}

					function getBonusGameData(scenario)
					{
						return scenario.split("|")[4].split(",");
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;
						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
