//
// Localization strings for TTDPatch.
//

//-------------------------------------------
//  INFO ABOUT THIS LANGUAGE
//-------------------------------------------
SETNAME("Norwegian")
SETCODE("no")
COUNTRYARRAY(countries) = { 47, 0, 0x14, 0 };
SETARRAY(countries);

DOSCODEPAGE(850)	// The default DOS code page for this language
WINCODEPAGE(1252)	// The default Windows code page for this language
EDITORCODEPAGE(850)	// The code page of all strings in this file.

DOSENCODING(IBM850)	// Encoding type for XML output from DOS and Windows;
WINENCODING(ISO-8859-1)	// DOS MUST be from IANA-CHARSETS and same as DOSCODEPAGE
			// Windows can be any ISO-8859-x encoding, doesn't have
			// to be related to WINCODEPAGE

//-------------------------------------------
//  PROGRAM BLURBS
//-------------------------------------------

// First line of output is something like "TTDPatch V1.5.1 starting.\n"
// The program name and version are autogenerated, only put the " starting\n"
// here
SETTEXT(LANG_STARTING, " starter.\n")


//-------------------------------------------
//  VERSION CHECKING
//-------------------------------------------

// In the version identifier, this is for the file size
SETTEXT(LANG_SIZE, "st�rrelse")

// Shown if the version is recognized
SETTEXT(LANG_KNOWNVERSION, "Denne versjonen av programmet har kjente adresser.\n")

// Warning if the version isn't recognized.  Be sure *not* to use tabs
// in the text.  All but the last lines should end in ...\n"
SETTEXT(LANG_WRONGVERSION, "\n"
	"ADVARSEL! Din versjon av programmet gjenkjennes ikke av dette programmet. Vi\n"
	"          kan pr�ve � starte det likevel og finne n�dvendig informasjon, men\n"
	"          dersom det sl�r feil, vil TTD motta en beskyttelsesfeil og avslutte.\n"
	"\n"
	"          Avhengig av hvor godt operativsystemet ditt handterer en GPF, kan\n"
	"          dette f�re til at maskinen din henger. Du kan miste data. Vennligst\n"
	"          se i avsnitt 4.1 i TTDPATCH.TXT for mer informasjon.\n"
	"\n"
	"Svar 'j' bare hvis du virkelig vet hva du gj�r. DU HAR BLITT ADVART!\n"
	"Vil du starte TTD allikevel? ")

// Keys which continue loading after the above warning. *MUST* be lower case.
// can be several different keys, e.g. one for your language "yjo"
SETTEXT(LANG_YESKEYS, "j")

// Answering anything but the above keys gives this message.
SETTEXT(LANG_ABORTLOAD, "Lasting av program avbrutt.\n")

// otherwise continue loading
SETTEXT(LANG_CONTINUELOAD, "Jeg skal gj�re mitt beste...\n")

// Warning if '-y' was used and the version is unknown
SETTEXT(LANG_WARNVERSION, "ADVARSEL: Ukjent versjon!\n")


// -------------------------------------------
//    CREATING AND PATCHING TTDLOAD
// -------------------------------------------

// TTDLOAD.OVL doesn't exist
SETTEXT(LANG_OVLNOTFOUND, " ikke funnet, leter etter orginalfilene:\n")

// (DOS) neither do tycoon.exe or ttdx.exe.  %s is TTDX.EXE
SETTEXT(LANG_NOFILESFOUND, "Fant hverken TYCOON.EXE eller %s.\n")

// (Windows) neither does GameGFX.exe.  %s is GameGFX.EXE
SETTEXT(LANG_NOFILEFOUND, "Kunne ikke finne %s.\n")

// Shown when copying tycoon.exe or ttdx.exe (first %s) to ttdload.ovl (2nd %s)
SETTEXT(LANG_SHOWCOPYING, "Kopierer %s til %s")

// Error if running the copy command fails.  %s is the command.
SETTEXT(LANG_COPYERROR_RUN, "Kunne ikke kj�re %s\n")

// Error if command returned successfully, but nothing was copied.
// %s=TTDLOAD.OVL
SETTEXT(LANG_COPYERROR_NOEXIST, "Kopieringsfeil - filen %s eksisterer ikke.\n")

// Invalid .EXE format
SETTEXT(LANG_INVALIDEXE, "Ukjent .EXE-format.\n")

// Version could not be determined
SETTEXT(LANG_VERSIONUNCONFIRMED, "Kunne ikke fastsette programversjonen.\n")

// Shows program name (1st %s) and version (2nd %s)
SETTEXT(LANG_PROGANDVER, "Programnavnet er %s\nDen eksakte versjonen er %s\n")

// More than three numbers in the version string (not #.#.#)
SETTEXT(LANG_TOOMANYNUMBERS, "Versjonsnummeret har for mange siffer!\n")

// .EXE is not TTD
SETTEXT(LANG_WRONGPROGRAM, "Dette er ikke Transport Tycoon Deluxe.\n")

// Displays the parsed version number
SETTEXT(LANG_PARSEDVERSION, "Analysert versjonsnummer er %s\n")

// The exe has been determined to be the DOS extended executable
SETTEXT(LANG_ISDOSEXTEXE, "Dette er den kj�rbare filen for DOS utvidet modus.\n")

// The exe has been determined to be the Windows executable
SETTEXT(LANG_ISWINDOWSEXE, "Dette er den kj�rbare filen for Windows.\n")

// The exe is of an unknown type
SETTEXT(LANG_ISUNKNOWNEXE, "Dette er et ukjent kj�rbart format.\n")

// The exe is the wrong one for this TTDPatch, i.e. DOS/Windows mixed up. %s=DOS or Windows
SETTEXT(LANG_NOTSUPPORTED, "Desverre, denne versjonen av TTDPatch fungerer kun med %s-versjonen.\n")

// If the original .exe segment length (%lx) is too large or too small
SETTEXT(LANG_INVALIDSEGMENTLEN, "Ugyldig original segmentlengde p� %lx.")

// When increasing the segment length
SETTEXT(LANG_INCREASECODELENGTH, "Setter programst�rrelse til %s MB.\n")

// Can't write to TTDLOAD.OVL (%s) [or TTDLOADW.OVL for the Windows version]
SETTEXT(LANG_WRITEERROR, "Kan ikke skrive til %s, er den skrivebeskyttet?\n")

// Installing the code loeader
SETTEXT(LANG_INSTALLLOADER, "Installerer kodelaster.\n")

// TTDLOAD.OVL (%s) is invalid, needs to be deleted.
SETTEXT(LANG_TTDLOADINVALID, "Kunne ikke installere kodelaster")

// Suggestion to delete TTDLOAD.OVL (%s) if it is invalid
SETTEXT(LANG_DELETEOVL, " - pr�v � slette %s.\n")

// TTDLOAD.OVL was verified to be correct
SETTEXT(LANG_TTDLOADOK, "%s er OK.\n")
 
// Waiting for key before terminating TTDPatch after an error occured
SETTEXT(LANG_PRESSANYKEY, "Trykk en tast for � avbryte.")

// Displayed on various warning conditions: Esc to exit, any other key to continue
SETTEXT(LANG_PRESSESCTOEXIT, "Trykk Escape for � avbryte, eller en annen tast for � fortsette")


// Loading custom in-game texts
SETTEXT(LANG_LOADCUSTOMTEXTS, "Laster modifiserte spill-tekster.\n")

// ttdpttxt.dat is not in a valid format
SETTEXT(LANG_CUSTOMTXTINVALID, "Lese %s: Ugyldig filformat.\n")

SETTEXT(LANG_CUSTOMTXTWRONGVER,
	"%s m� bygges om for denne versjonen av TTDPatch.\n"
	"Last ned og kj�r det siste mkpttxt.exe programmet.\n")




//-----------------------------------------------
//   COMMAND LINE HELP (-h)
//-----------------------------------------------

// Introduction, prefixed with "TTDPATCH V<version> - "
SETTEXT(LANG_COMMANDLINEHELP, "Patcher TTD og starter det patcha programmet %s\n"
	  "\n"
	  "Bruk: TTDPATCH [-C cfg-fil] [opsjoner] [CD-sti] [-W cfg-fil]\n"
	  "\n")

// Lines of help for all on/off switches, each at most 38 chars long.
// If you need more chars just insert another line.
TEXTARRAY(halflines,) =
	{ "-a:  Alle opsjoner unntatt -x",
	  "-d:  Vis alltid full dato",
	  "-f:  Gj�r tog ombyggbare",
	  "-g:  Generelle modifikasjoner",
	  "-k:  Behold sm� flyplasser",
	  "-l:  Opp til 7 perronger",
	  "-n:  Ny handtering av non-stop",
	  "-q:  Regulert laste/lossetidsalgoritme",
	  "-s:  Muliggj�re juksing med skilt",
	  "-v:  Liste ut valgene n�r de aktiveres",
	  "-w:  Sl� p� pre-signal-oppsett",
	  "-y:  Skippe sp�rsm�l om ukjent versjon",
	  "-z:  Mammut-tog (126 vogner)",

     "-2:  Noen Windows 2000 patcher",

	  "-B:  Tillate lengre bruer",
	  "-D:  Dynamitt kan �delegge flere ting",
	  "-E:  Flytte vinduer med feilmelding",
	  "-F:  'Full load' betyr hvilken type",
	  "     last som helst",
	  "-G:  Valgbare godstyper pr stasjon",
	  "-I:  Sl� av inflasjon",
	  "-J:  Tillat flere flyplasser pr by",
	  "-L:  L�n/tilbakebetal maks med 'Ctrl'",
	  "-N:  Nyheter om flere hendelser",
	  "-O:  Kontorbygg tar imot mat",
	  "-P:  Vedholdende lokomotiver",
	  "-R:  Busser/biler stiller seg i k�",
	  "-S:  Nye skipsmodeller",
	  "-T:  Nye togmodeller",
	  "-Z:  Lite-minne-versjon (3.5MB)",

	  "-Xb: Mulighet for � bestikke",
	  "     lokale myndigheter",
	  "-Xd: Legg til depoer i kj�reordrene",
	  "-Xe: Evig spill etter 2070",
	  "-Xf: 'Feeder service' ved",
	  "      tvunget lossing",
	  "-Xg: Trinnvis lasting av kj�ret�y",
	  "-Xi: Ingen industri g�r konkurs med",
	  "     'stable economy' instillingen",
	  "-Xm: Mulighet for � laste et spill",
	  "     i programmenyen",
	  "-Xo: 'Skiltjuks' koster penger",
	  "-Xr: Bygg alltid opp igjen TTDLOAD.OVL",
	  "-Xs: Vis farten i statuslinjen",
	  "-Xw: Utvidet f�r-signal oppsett",
     "-Xx: Lagre og laste ekstra data",

	  "-XA: Tvunget auto-fornying med -Xa",
	  "-XE: Elektrisk jernbane",
	  "-XF: Sl� p� eksperimentelle egenskaper",
	  "-XG: Alltid last inn all ny grafikk",
	  "-XP: Nye flymodeller",
	  "-XR: Nye kj�ret�y",
	  "-XS: Administrere datterselskap",
  	  "-Ya: Mer tolerant Anseelse (rating)",
  	  "     til kj�ret�y- og vognalder",

	  "-Yb: Bygge mer p� bakker og skr�ninger",
	  "-Yc: Sportyper har forskj. kostnader",
	  "-Ym: Tillat manuell sporombygging",
	  "-Ys: Jernbanesignaler p� samme side",
	  "     som kj�reretning p� vei",
	  "-Yt: Vis mer statistikk i byvinduet",
	  "-Yw: Raskere salg av vogner",

	  "-YC: Bygg rett p� kystlinjen",
	  "-YH: Flere/nye hurtigtaster",
	  "-YP: Flyene flyr i gitt hastighet",
	  "-YS: Semaforflagg f�r 1975",

	  NULL
	};
SETARRAY(halflines);

// Text describing the switches with values.  The lines have to be shorter
// than 79 chars, excluding the "\n".  Start new lines if necessary.
SETTEXT(LANG_FULLSWITCHES, "\n"
	  "-e #:    �k mulig stasjonsspredning\n"
	  "-i #:    Standard service-intervall er det oppgitte antall dager\n"
	  "-x #:    �k kj�ret�ytabellen til 850*#. Les dokumentasjonen!\n"
	  "-mc #:   Ny handtering av fjell (m) eller svinger (c)\n"
	  "-trpb #: �k antall tog (t), biler (r), fly (p) eller skip (s).\n"
	  "-A #:    Gj�r AI # trinn smartere. Bruk kun sm� verdier.\n"
	  "-M #:    Tillat fler-hodet tog, og sett farts�kning i prosent.\n"
     "-Xa #:   Automatisk forny kj�ret�y # m�neder f�r de blir gamle\n"
     "-Xc #:   Kontroller hvor ofte flyene havarerer\n"
	  "-Yr #:   Modifiser tog/bil kollisjoner til type (1/2)\n"
	  "-Xt #:   Sett den maksimale st�rrelsen en by kan vokse til\n"
	  "-XC #:   Tillat flere valutaer, og sett visningsmodus\n"
	  "-XD #:   Velg hvilke katastrofer som kan inntreffe\n"
	  "-XM #:   Kombiner monorail og maglev sporsystemer \n"
	  "-XT #:   Bestemme en av hvor mange byer som blir st�rre\n"
	  "-XX #:   Ny monorail og maglev fart p� brua, gitt i prosent av maks fart\n"
	  "-XY #:   Sette start�ret for nye random spill\n"
	  "-X1 #, -X2 #: Hvor mange dager et tog venter p� henholdsvis\n"
  	  "              enveis- eller toveis-signaler\n"
	  "-Yo #:   Kontrollere noen muligheter for andre brytere (se dokumentasjonen)\n"
	  "-Yp #:   Tillat � plante flere tr�r, velg plantemodell\n"
	  "-YB #:   Flere byggemuligheter, velg muligheter\n"
	  "-YE #:   Sette hvor mange sekunder den r�de feilmeldingsboksen vises\n"
	  "-YG #:   Forbedre brukergrensesnittet, velg mulighet med parameter\n"
	  "-YT #:   Sette byvekts algoritme\n"
	  "\n"
	  "-C cfg-fil:  Bruk denne cfg-fila i stedet for ttdpatch.cfg\n"
	  "-W cfg-fil:  Oppretter en cfg-fil med gjeldende konfigurasjon\n"
	  "\n"
	  "Sm� og store bokstaver er viktig!\n"
	  "\n"
	  "Eksempel:  ttdpatch -fnqz -m 00 -c 13 -trpb 240 -FG -A 2 -v\n"
	  "\n"
	  "(Hint:  Hvis alt forsvant vekk alt for fort, skriv \"ttdpatch -h|more\")\n"
	  "\n")

// Referral to the docs, prefixed by "Copyright (C) 1999 by Josef Drexler.  "
SETTEXT(LANG_HELPTRAILER, "Les TTDPATCH.TXT for flere detaljer.\n")


//-----------------------------------------------
//  COMMAND LINE AND CONFIG FILE PARSING
//-----------------------------------------------

// if an on/off switch has a value other than the above (%s = wrong value)
SETTEXT(LANG_UNKNOWNSTATE, "Advarsel: Ukjent p�/av-status %s, sl�s av.\n")

// switch is unknown.  %c is '-' or '/' etc, %s is the switch char
SETTEXT(LANG_UNKNOWNSWITCH, "Ukjent valg '%c%s'.  Bruk -h for hjelp.\n")

// cfg command %s is unknown
SETTEXT(LANG_UNKNOWNCFGLINE, "Advarsel: Ugyldig cfg-linje '%s'.\n")

// Names of the switches for the '-v' options
// First string is shown always, second only if set and with the given
// value of the switch in %d.
// These lines (both parts) are limited to 36 chars, also consider how large
// the expansion of the %d can be for that switch.
SWITCHTEXT(uselargerarray, "�k totalt ant. kj�ret�y", " til %d*850")
SWITCHTEXT(usenewcurves, "Ny svinghandtering", " for %04x")
SWITCHTEXT(usenewmountain, "Ny fjellhandtering", " for %04x")
SWITCHTEXT(usenewnonstop, "Ny non-stop-handtering", "")
SWITCHTEXT(increasetraincount, "Nytt togantall", ": %d")
SWITCHTEXT(increaservcount, "Nytt bilantall", ": %d")
SWITCHTEXT(setnewservinterval, "Nytt std service-int", ": %d dager")
SWITCHTEXT(usesigncheat, "Bruk skilt-juksing", "")
SWITCHTEXT(allowtrainrefit, "Tillat ombygging av tog", "")
SWITCHTEXT(increaseplanecount, "Nytt flyantall", ": %d")
SWITCHTEXT(increaseshipcount, "Nytt skipsantall", ": %d")
SWITCHTEXT(keepsmallairports, "Behold sm� flyplasser", "")
SWITCHTEXT(largerstations, "�k stasjonsspredning", " til %d kv.")
SWITCHTEXT(morestationtracks, "Utvidbare stasjoner", "")
SWITCHTEXT(longerbridges, "Lengre bruer", "")
SWITCHTEXT(improvedloadtimes, "Forbedret beregning av lastetid", "")
SWITCHTEXT(mammothtrains, "Mammut-tog (lengde 127)", "")
SWITCHTEXT(presignals, "Bruk f�r-signaler", "")
SWITCHTEXT(officefood, "Kontorbygg tar imot mat", "")
SWITCHTEXT(noinflation, "Sl� av inflasjon", "")
SWITCHTEXT(maxloanwithctrl, "Maks l�n/tilbakebetal med 'Ctrl'", "")
SWITCHTEXT(persistentengines, "Alltid tilgj. lokomotiver", "")
SWITCHTEXT(fullloadany, "'Full load' betyr uansett last", "")
SWITCHTEXT(selectstationgoods, "Valgbare godstyper pr stasjon", "")
SWITCHTEXT(morethingsremovable, "Spreng flere ting", "")
SWITCHTEXT(aibooster, "Gj�r AI smartere", " med %d trinn")
SWITCHTEXT(multihead, "Flere lokomotiver pr tog", "")
SWITCHTEXT(newlineup, "Biler stiller seg i k�", "")
SWITCHTEXT(lowmemory, "Lite-minne-versjon (3.5MB)", "")
SWITCHTEXT(generalfixes, "Generelle modifikasjoner (se dok)", "")
SWITCHTEXT(moreairports, "Flere flyplasser pr by", "")
SWITCHTEXT(bribe, "Vis mulighet for bestikkelse", "")
SWITCHTEXT(noplanecrashes, "Flykrasjkontroll", ": %d")
SWITCHTEXT(showspeed, "Vis fart i statuslinjen", "")
SWITCHTEXT(autorenew, "Autofornye kj�ret�y", " ved %d m�neder")
SWITCHTEXT(cheatscost, "Skiltjuks koster penger", "")
SWITCHTEXT(extpresignals, "Juster f�r-signaler med 'Ctrl'", "")
SWITCHTEXT(diskmenu, "Vis 'Load' i diskmenyen", "")
SWITCHTEXT(win2k, "Gj�r spillet kj�rbart p� Win2k/XP", "")
SWITCHTEXT(feederservice, "'Feeder service' ved tvunget lossing", "")
SWITCHTEXT(gotodepot, "Legg til depoter i kj�reinstruksene", "")
SWITCHTEXT(newships, "Nye skipsmodeller", "")
SWITCHTEXT(subsidiaries, "Administrer datterselskap", "")
SWITCHTEXT(gradualloading, "Trinnvis lasting av kj�ret�y", "")
SWITCHTEXT(moveerrorpopup, "Flytt vinduer med feilmeldinger", "")
SWITCHTEXT(setsignal1waittime, "Ny ventetid for tog ved signaler", ":")
SWITCHTEXT(setsignal2waittime, "", "")				// dummy entry
SWITCHTEXT(maskdisasters, "Valg av katastrofer", ": %d")
SWITCHTEXT(forceautorenew, "Tvungen auto-utbytting av kj�ret�y", "")
SWITCHTEXT(unifiedmaglev, "Sammensl�tt maglev", ", modus %d")
SWITCHTEXT(newbridgespeeds, "Max. fart p� maglev bruer", ": %d%%")
SWITCHTEXT(eternalgame, "Evig spill etter 2070", "")
SWITCHTEXT(showfulldate, "Alltid vis full dato", "")
SWITCHTEXT(newtrains, "Nye togmodeller", "")
SWITCHTEXT(newrvs, "Nye kj�ret�ymodeller", "")
SWITCHTEXT(newplanes, "Nye flymodeller", "")
SWITCHTEXT(signalsontrafficside, "Signaler p� 'trafikk'siden av sporet", "")
SWITCHTEXT(electrifiedrail, "Elektrisk jernbane", "")
SWITCHTEXT(newstartyear, "Standard start�r", ": %d")
SWITCHTEXT(newerrorpopuptime, "Ny feilvindu timout", ": %d sek.")
SWITCHTEXT(newtowngrowthfactor, "Forandre byvekst faktor", " til %d")
SWITCHTEXT(largertowns, "Store byer", ", hver 1 av %d")
SWITCHTEXT(miscmods, "Diverse mods", ": %d")
SWITCHTEXT(loadallgraphics, "Alltid last all grafikk", "")
SWITCHTEXT(saveoptdata, "Lagre og laste mer data", "")
SWITCHTEXT(morebuildoptions, "Flere byggemuligheter", ": %d")
SWITCHTEXT(semaphoresignals, "Semaforer f�r 1975", "")
SWITCHTEXT(morehotkeys, "Fler/nye hurtigtaster", "")
SWITCHTEXT(plantmanytrees, "Plante mange tr�r", ", modus %d")
SWITCHTEXT(morecurrencies, "Tillat flere valuttaer", ", flagg: %d")
SWITCHTEXT(manualconvert, "Tillat manuell sporombygging", "")
SWITCHTEXT(newtowngrowthrate, "Ny byvekst algoritme", ": %d")
SWITCHTEXT(displmoretownstats, "Vis mer bystatistikk", "")
SWITCHTEXT(enhancegui, "Forbedret brukergrensesnitt", ": %d")
SWITCHTEXT(newagerating, "Rating mer tolerant til kj.t�yalder", "")
SWITCHTEXT(buildonslopes, "Bygg flere ting p� skr�ninger", "")
SWITCHTEXT(buildoncoasts, "Bygg rett p� kystlinjen", "")
SWITCHTEXT(experimentalfeatures, "Sl� p� nyeste eksperimentelle ting", ": %d")
SWITCHTEXT(tracktypecostdiff, "Sportyper har forskjellig pris", "")
SWITCHTEXT(planespeed, "Bruk reell flyfart", "")
SWITCHTEXT(fastwagonsell, "Raskere salg av vogner", "")
SWITCHTEXT(newrvcrash, "Forandre tog/bil ulykker"," (modus %d)")
SWITCHTEXT(stableindustry, "Hindre stenging av industri","")
SWITCHTEXT(morenews, "Nyheter om flere hendelser", "")


// A cfg file (%s) could not be found and is ignored.
SETTEXT(LANG_CFGFILENOTFOUND, "Kunne ikke finne cfg-fila %s.  Ignorert.\n")

// Couldn't write the config file
SETTEXT(LANG_CFGFILENOTWRITABLE, "Kunne ikke �pne %s for skriving.\n")

// A non-comment line is longer than 32 chars, rest ignored.
SETTEXT(LANG_CFGLINETOOLONG, "Advarsel! Konfigurasjonslinjen er lengre enn 32 tegn, avkortet.\n")

// Shown if an obsolete switch is used. First option is %s which is the
// config name, second one is %s which is the command line char
SETTEXT(LANG_SWITCHOBSOLETE, "Opsjonen `%s' (%s) er utdatert. Vennligst ikke bruk den. Den vil\n"
		"bli fjernet i en framtidig versjon.\n")

//---------------------------------------------------
//   CONFIG FILE COMMENTS (for '-W')
//---------------------------------------------------

// This is the intro at the start of the config file.  No constraints on line lengths.
SETTEXT(CFG_INTRO,
	CFG_COMMENT "\n"
	CFG_COMMENT "TTDPatch konfigurasjonsfil, automatisk opprettet med TTDPatch -W filnavn.\n"
	CFG_COMMENT "(TTDPatch %s)\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Formatet p� valgene er:\n"
	CFG_COMMENT "   valg = verdi\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "\"=\" kan skippes, det samme kan mellomrom.  Store/sm� bokstaver er uvesentlig.\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "For ja/nei-opsjoner [y/n] kan verdien v�re en av f�lgende:\n"
	CFG_COMMENT "   yes, y, on, 1, no, n, off, 0\n"
	CFG_COMMENT "Hvis verdien ikke er opgitt, er standardverdien ja (yes).\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "For opsjoner som kan ha en verdi [v] er intervallet oppgitt i beskrivelsen,\n"
	CFG_COMMENT "og det gjelder ogs� standardverdien dersom verdien ikke er oppgitt. Valget\n"
	CFG_COMMENT "kan sl�s av ved � oppgi en av 'av'-verdiene.\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Kommentarer er alle linjer som starter med et ikke-alfabetisk tegn.\n"
	CFG_COMMENT "\n")

// Line before previously unset switches
SETTEXT(CFG_NEWSWITCHINTRO, "**** Nye brytere ****")

// For switches which have no command line equivalent
SETTEXT(CFG_NOCMDLINE, "kommandolinjebryter ikke tilgjengelig")

// Definitions of the cfg file comments.
// All can have a place holder %s to stand for the actual setting name,
// and all but CFG_CDPATH can have a %s *after* the %s for the command
// line switch.
// They will have the "comment" char and a space prefixed.
//
SETTEXT(CFG_SHIPS, "`%s' (%s) �ker maksimalt antall skip.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_CURVES, "`%s' (%s) setter hastigheten i kurver til normal (0), raskere (1), raskest (2) eller realistisk (3).  Ett siffer for jernbane, monorail, maglev og kj�ret�y.  Standard 0120.")
SETTEXT(CFG_MOUNTAINS, "`%s' (%s) setter hastigheten i bakker til normal (0), raskere (1), raskest (2) eller realistisk (3).  Ett siffer for jernbane, monorail, maglev og kj�ret�y.  Standard 0120.")
SETTEXT(CFG_SPREAD, "`%s' (%s) muliggj�r st�rre stasjonsspredning.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TRAINREFIT, "`%s' (%s) gj�r det mulig � bygge om lokomotiver.")
SETTEXT(CFG_SERVINT, "`%s' (%s) tillater endring av opprinnelig service-intervall for nye lokomotiver.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_NOINFLATION, "`%s' (%s) Sl�r av all inflasjon, b�de for kostnader og inntekter.")
SETTEXT(CFG_LARGESTATIONS, "`%s' (%s) tillater flere perronger og lengre stasjoner, opp til 15x15.")
SETTEXT(CFG_NONSTOP, "`%s' (%s) f�rer til at \"Non-stop\"-valget oppf�rer seg annerledes.")
SETTEXT(CFG_PLANES, "`%s' (%s) �ker maksimalt antall fly.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_LOADTIME, "`%s' (%s) sl�r p� alternativ m�te for beregning av losse/lastetider.")
SETTEXT(CFG_ROADVEHS, "`%s' (%s) �ker maksimalt antall biler.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_SIGNCHEATS, "`%s' (%s) sl�r p� skilt-juksing.")
SETTEXT(CFG_TRAINS, "`%s' (%s) �ker maksimalt antall tog.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_VERBOSE, "`%s' (%s) viser oppsummering av valgene f�r oppstart av TTD.")
SETTEXT(CFG_PRESIGNALS, "`%s' (%s) tillater bruken av 'f�r-signaler' for � forbedre h�ndteringen av stasjoner.")
SETTEXT(CFG_MOREVEHICLES, "`%s' (%s) �ker totalt antall kj�ret�y til verdi*850.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_MAMMOTHTRAINS, "`%s' (%s) tillater mammut-tog med opptil 126 vogner.")
SETTEXT(CFG_FULLLOADANY, "`%s' (%s) f�r et tog til � dra fra stasjonen dersom det er fullt av en hvilken som helst last.")
SETTEXT(CFG_SELECTGOODS, "Med `%s' (%s) ankommer gods kun etter at tjenesten er startet opp.")
SETTEXT(CFG_DEBTMAX, "`%s' (%s) sl�r p� l�n/tilbakebetaling av maksimalt bel�p ved � trykke 'Ctrl'.")
SETTEXT(CFG_OFFICEFOOD, "`%s' (%s) gj�r at kontorbygninger tar imot mat (tropiske/arktiske scenarier).")
SETTEXT(CFG_ENGINESPERSIST, "`%s' (%s) beholder lokomotiver s� lenge de er i bruk (uendelig levetid).")
SETTEXT(CFG_CDPATH, "`%s' (%s) setter stien til CD'en.")
// Note- CFG_CDPATH has no command line switch, so don't give %s!
SETTEXT(CFG_KEEPSMALLAP, "`%s' (%s) beholder sm� flyplasser gjennom hele spillet.")
SETTEXT(CFG_AIBOOST, "`%s' (%s) �ker AI sin rekursjonsevne (intelligens) med den angitte verdien.")
SETTEXT(CFG_LONGBRIDGES, "`%s' (%s) tillater bruer som er 127 felt lange.")
SETTEXT(CFG_DYNAMITE, "`%s' (%s) tillater sprenging av flere ting ved hjelp av dynamitt.")
SETTEXT(CFG_MULTIHEAD, "`%s' (%s) tillater et vilk�rlig antall lokomotiver p� ett tog. Kj�p ekstra lokomotiver med 'Ctrl'.")
SETTEXT(CFG_RVQUEUEING, "`%s' (%s) gj�r at biler stiller seg i k� foran en stasjon i stedet for � snu.")
SETTEXT(CFG_LOWMEMORY, "`%s' (%s) tillater at TTDPatch kj�rer med  3.5MB minne, men reduserer maks-verdien til den utvidede kj�ret�ytabellen til 2.")
SETTEXT(CFG_GENERALFIXES, "`%s' (%s) generelle modifikasjoner. Se dokumentasjonen for mer info dette.")
SETTEXT(CFG_MOREAIRPORTS, "`%s' (%s) tillater bygging av flere flyplasser enn de vanlige to pr by.")
SETTEXT(CFG_BRIBE, "`%s' (%s) gir deg en mulighet til � bestikke de lokale myndighetene")
SETTEXT(CFG_PLANECRCTRL, "`%s' (%s) tillater deg � kontrollere n�r flyene har lov til � krasje. Bitverdi, standard 1.")
SETTEXT(CFG_SHOWSPEED, "`%s' (%s) viser farten i vinduene til kj�ret�yene.")
SETTEXT(CFG_AUTORENEW, "`%s' (%s) fornyer kj�ret�y n�r de f�r service s� mange m�neder etter de har blitt veldig gamle.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_CHEATSCOST, "`%s' (%s) gj�r at skilt-juks koster penger.")
SETTEXT(CFG_EXTPRESIGNALS, "`%s' (%s) tillater sirkulering av normale-, f�r-, utgangs- og kombinerte signaler med 'Ctrl'.")
SETTEXT(CFG_FORCEREBUILDOVL, "`%s' (%s) gj�r at TTDPatch bygger om TTDLOAD.OVL eller TTDLOADW.OVL hver gang den er startet.")
SETTEXT(CFG_DISKMENU, "`%s' (%s) legger til 'load game' p� diskmenyen, og en 'load game' (eller lagre med 'Ctrl') til scenario editoren.")
SETTEXT(CFG_WIN2K, "`%s' (%s) vil gj�re windowsversjonen kompatibel med Windows 2000/XP.")
SETTEXT(CFG_FEEDERSERVICE, "`%s' (%s) modifiserer tvunget lossing og profitten p� en stasjon som aksepterer denne lasten, til � la lasten v�re p� stasjonen, dvs ikke inkassere")
SETTEXT(CFG_GOTODEPOT, "`%s' (%s) tillater � ha depoter i kj�ret�yets ordre.")
SETTEXT(CFG_NEWSHIPS, "`%s' (%s) forandrer skipsmodellene og legger til flere skipstyper.")
SETTEXT(CFG_SUBSIDIARIES, "`%s' (%s) tillater deg � administrere datterselskap hvis du eier 75%% av det.")
SETTEXT(CFG_GRADUALLOADING, "`%s' (%s) forandrer m�ten kj�ret�yene er lastet p�, til en mer realistisk trinnvis lasting (aktiverer ogs� `loadtime').")
SETTEXT(CFG_MOVEERRORPOPUP, "`%s' (%s) flytter alle r�de feilmeldingsvinduer til �verste h�yre hj�rne av skjermen.")
SETTEXT(CFG_SIGNAL1WAITTIME, "`%s' (%s) endrer antall dager et tog venter ved et enveis-signal, f�r det snur. Intervall 0..254, eller 255 for � vente evig.")
SETTEXT(CFG_SIGNAL2WAITTIME, "`%s' (%s) endrer antall dager et tog venter ved et toveis-signal, f�r det snur. Intervall 0..254, eller 255 for � vente evig")
SETTEXT(CFG_DISASTERS, "`%s' (%s) Tillater deg � velge hvilke katastrofer som kan intreffe.  Bitkodet verdi, standard 255 (alle katastrofer).")
SETTEXT(CFG_FORCEAUTORENEW, "`%s' (%s) tvungen service av kj�ret�y n�r det er tid for auto-utbyttingen (se `autorenew').")
SETTEXT(CFG_MORENEWS, "`%s' (%s) genererer meldinger/nyhets-overskrifter for flere hendelser. Se dokumentasjonen for mer informasjon.")
SETTEXT(CFG_UNIFIEDMAGLEV, "`%s' (%s) gj�r det mulig � kj�pe maglevtog i monoraildepoer og omvendt.  Modus: 1 - konverter alle maglevtog til monorail; 2 - konverter alle monorailtog til maglevtog; 3 - behold separat monorail og maglev.")
SETTEXT(CFG_BRIDGESPEEDS, "`%s' (%s) forandrer fartsgrensen p� r�rformet monorail- og maglevbruer til denne prosentsatsen av den h�yeste maksimale motorvognfarten i denne klassen. Omr�de %ld..%ld. Standard %ld.")
SETTEXT(CFG_ETERNALGAME, "`%s' (%s) tillater deg � spille for evig. Datoen vil ikke bli resatt etter 2070.")
SETTEXT(CFG_SHOWFULLDATE, "`%s' (%s) viser alltid full dato. Ikke bare n�r spillet er pauset.")
SETTEXT(CFG_NEWTRAINS, "`%s' (%s) aktiverer nye togmodeller med ny grafikk.")
SETTEXT(CFG_NEWRVS, "`%s' (%s) aktiverer nye kj�ret�ymodeller med ny grafikk.")
SETTEXT(CFG_NEWPLANES, "`%s' (%s) aktiverer nye fly med ny grafikk.")
SETTEXT(CFG_SIGNALSONTRAFFICSIDE, "`%s' (%s) viser jernbanesignaler p� samme side som bilene kj�rer p� veien")
SETTEXT(CFG_ELECTRIFIEDRAIL, "`%s' (%s) fjerner en av de magnetiske banene (Monorail eller MagLev) og erstatter dem med elektrisk jernbane.")
SETTEXT(CFG_STARTYEAR, "`%s' (%s) setter start�ret for random-spill, og gir en st�rre frihet i scenario-editoren  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_ERRORPOPUPTIME, "`%s' (%s) forandrer tiden det vil ta f�r det r�de feilmeldingsvinduet forsvinner.  Intervall 1..255 (i sekunder), eller 0 for veldig lang tid.  Standard 10.")
SETTEXT(CFG_TOWNGROWTHLIMIT, "`%s' (%s) forandrer faktoren som bestemmer det maksimale omfanget av byene.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_LARGERTOWNS, "`%s' (%s) gj�r at en ut av et gitt antall vokser seg st�rre (sl�r ogs� p� `towngrowthlimit').  Intervall %ld..%ld.  Standard %ld (En av fire byer).")
SETTEXT(CFG_MISCMODS, "`%s' (%s) gj�r det mulig � forandre hvordan noen av bryterene fungerer. Se dokumentasjonen for mer info.  Bitverdi, standard 0 (ingen justering).")
SETTEXT(CFG_LOADALLGRAPHICS, "`%s' (%s) tvinger TTDPatch til � laste alle .grf files i newgrf(w).cfg, selv om de ikke har blitt brukt i et tidligere spill (etc.) eller ikke.")
SETTEXT(CFG_SAVEOPTDATA, "`%s' (%s) gj�r at TTDPatch vil lagre og hente ekstra (valgfri) data p� slutten av savegamene.")
SETTEXT(CFG_MOREBUILDOPTIONS, "`%s' (%s) sl�r p� fler byggemuligheter. Bitverdi, intervall %ld..%ld. Standard %ld.")
SETTEXT(CFG_SEMAPHORES, "`%s' (%s) gj�r at nye signaler bygd f�r 1975 blir semaforsignaler.")
SETTEXT(CFG_MOREHOTKEYS, "`%s' (%s) sl�r p� nye hurtigtaster.")
SETTEXT(CFG_MANYTREES, "`%s' (%s) tillater planting av fler tr�r p� en rute, eller over et rektangul�rt omr�de med Ctrl.")
SETTEXT(CFG_MORECURRENCIES,"`%s' (%s) tillater flere valutaer og Euroen.  Parametre: 0 - valutategn p� standard plass; 1 - valuttategnene f�r tallene; 2 - valuttategnene etter tallene.  Legg til fire p� ett av de tallene og sl� av Euroen.")
SETTEXT(CFG_MANCONVERT,"`%s' (%s) tillater manuell sportypekonvertering ved � legge ny type opp� gammel.")
SETTEXT(CFG_NEWAGERATING, "`%s' (%s) lar stasjonene v�re litt mer tollerante til vognalder. N� kan vognene v�re 21 �r, istedet for tre.")
SETTEXT(CFG_ENHANCEGUI,"`%s' (%s) forbedrer brukergrensesnittet.")
SETTEXT(CFG_TOWNGROWTHRATEMODE, "`%s' (%s) gj�r det mulig � definere regler for vekstraten til byer.  Modus: 0 - TTD orginal, 1 - TTD utvidet, 2 - skreddersydd.  Se dokumentasjonen for mer informasjon.")
SETTEXT(CFG_TOWNGROWTHRATEMIN, "`%s' (%s) definerer minimumsveksten til byene, i nye hus pr. �rhundre.  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TOWNGROWTHRATEMAX, "`%s' (%s) definerer maksimumsveksten til byene, i nye hus pr. �rhundre.  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRACTSTATIONEXIST, "`%s' (%s) definerer hvor mye tilstedev�rende stasjoner p�virker veksten til en by (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Default %ld.")
SETTEXT(CFG_TGRACTSTATIONS, "`%s' (%s) definerer hvor mye hver aktive stasjon �ker veksten til en by (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRACTSTATIONSWEIGHT, "`%s' (%s) definerer hvor effektivt hver aktive stasjon bidrar til veksten de n�rliggende byene (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRPASSOUTWEIGHT, "`%s' (%s) definerer hvor mye transporterte passasjerer bidrar til byveksten (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRMAILOUTWEIGHT, "`%s' (%s) definerer hvor mye transportert post bidrar til byveksten (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRPASSINMAX, "`%s' (%s) definerer maksniv�et innkommende passasjerer bidrar til byveksten (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRPASSINWEIGHT, "`%s' (%s) definerer hvor effektivt innkommende passasjerer bidrar til byveksten (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRMAILINOPTIM, "`%s' (%s) definerer det optimale anntall innbyggere pr. hver andre sekk med post (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRMAILINWEIGHT, "`%s' (%s) definerer hvor effektivt innkommende post bidrar til byveksten (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRGOODSINOPTIM, "`%s' (%s) definerer det optimale anntall innbyggere pr. hver andre kasse gods (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRGOODSINWEIGHT, "`%s' (%s) definerer hvor effektivt innkommende gods bidrar til byveksten (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRFOODINMIN, "`%s' (%s) definerer minimum mat-ettersp�rsel i en by i sn�dekt landskap eller i �rkenomr�de, i innbyggere pr 2 tonn med innkommende mat (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRFOODINOPTIM, "`%s' (%s) definerer det optimale anntall innbyggere pr. hver andre tonn med innkommende mat (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRFOODINWEIGHT, "`%s' (%s) definerer hvor effektivt innkommende mat bidrar til byveksten (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRWATERINMIN, "`%s' (%s) definerer minimum mat-ettersp�rsel i en by i �rkenomr�de, i innbyggere pr 2 tonn (2000 liter) med innkommende vann (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRWATERINOPTIM, "`%s' (%s) definerer det optimale anntall innbyggere pr. 2 tonn (2000 liter) med innkommende vann i det tropiske klimaet (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRWATERINWEIGHT, "`%s' (%s) definerer hvor effektivt innkommende vann bidrar til byveksten i det tropiske klimaet (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRSWEETSINOPTIM, "`%s' (%s) definerer hvor effektivt hver andre sekk med godterier (sweets) bidrar til vekstraten i en by i toyland klimaet (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRSWEETSINWEIGHT, "`%s' (%s) definerer hvor effektivt hver andre last godterier (sweets) bidrar til vekstraten til en by i toyland klimaet. (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRFIZZYDRINKSINOPTIM, "`%s' (%s) definerer den optimale befolkningen pr. innkommende fizzy drinks i toyland klimaet (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRFIZZYDRINKSINWEIGHT, "`%s' (%s) definerer hvor mye fizzy drinks bidrar til vekstraten av en by i toyland klimaet. (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRTOWNSIZEBASE, "`%s' (%s) definerer grunnverdien med bygninger i kalkuleringa som involverer `tgrtownsizefactor' (se dokumentasjonen for mer info).  Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TGRTOWNSIZEFACTOR, "`%s' (%s) definerer hvor mye byens st�rrelse p�virker byveksten (se dokumentasjonen for mer info). Kun aktiv hvis `towngrowthratemode' er satt til 2.  Valg: %ld..%ld.  Standard %ld (dvs. 25%% innflytelse).")
SETTEXT(CFG_TOWNMINPOPULATIONSNOW, "`%s' (%s) definerer minimumbefolkning en by kan ha for at den kan vokse selv uten tilgang p� mat i det arktiske klimaet.  Aktiv hvis `towngrowthratemode', `towngrowthlimit' eller `generalfixes' er sl�tt p�.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_TOWNMINPOPULATIONDESERT, "`%s' (%s) definerer minimumsbeflkning en by kan ha for at den kan vokse selv uten tilgang p� vann i det tropiske klimaet.  Aktiv hvis `towngrowthratemode', `towngrowthlimit' eller `generalfixes' er sl�tt p�.  Intervall %ld..%ld.  Standard %ld.")
SETTEXT(CFG_MORETOWNSTATS, "With `%s' (%s) ekstra statistikk blir vist i by-vinduet .")
SETTEXT(CFG_BUILDONSLOPES, "`%s' (%s) gj�r det mulig � bygge p� tvers i skr�ninger p� fundament som f.eks hus blir bygd p�.")
SETTEXT(CFG_BUILDONCOASTS, "`%s' (%s) gj�r det mulig � bygge p� sandbanker uten � bruke dynamitt f�rst")
SETTEXT(CFG_TRACKTYPECOSTDIFF, "`%s' (%s) gj�r at de forskjellige sportypene koster forskjellig.")
SETTEXT(CFG_CUSMULTIPLIER, "`%s' (%s) setter valuttakursen for Custom Currency, CUS * 1000.  Standard er 1000 (1 CUS = 1 pund).  Kun aktiv hvis 'morecurrencies' er sl�tt p�.")
SETTEXT(CFG_EXPERIMENTALFEATURES, "`%s' (%s) sl�r p� de siste eksperimentelle mulighetene.")
SETTEXT(CFG_PLANESPEED, "`%s' (%s) f�r fly til � fly ved angitt fart og ikke en fjerdedel av den. Farten vil bli redusert til 5/8 ved motorhavari")
SETTEXT(CFG_FASTWAGONSELL, "`%s' (%s) tillater hurtigere salg av vogner ved � trykke Ctrl")
SETTEXT(CFG_NEWRVCRASH,"`%s' (%s) forandrer kollisjoner mellom tog og bil. 1 gj�r at toget vil bryte sammen etter sammenst�tet. 2 sl�r av slike kollisjoner helt. Standard: type 1.");
SETTEXT(CFG_STABLEINDUSTRY,"`%s' (%s) hindrer at industri g�r konkurs hvis 'Economy' er satt til 'Steady' p� options-menyen");


//----------------------------------------------------
//   SWITCH DISPLAY ('-v')
//----------------------------------------------------

// Wait for a key before displaying the switches
SETTEXT(LANG_SWWAITFORKEY, "\nTrykk Enter for � kj�re TTD, Escape for � avbryte, eller en annen tast for � vise instillingene.")

// Introduction
SETTEXT(LANG_SHOWSWITCHINTRO, "    Valg:   (%c p�sl�tt, %c avsl�tt)\n")

// Five characters: vertical line for the table; enabled switch; disabled switch;
// table heading; table heading column separator.
SETTEXT(LANG_SWTABLEVERCHAR, "�*���")

// 1-way and 2-way captions after "New train wait time on red signals"
SETTEXT(LANG_SWONEWAY, "En-veis: ")
SETTEXT(LANG_SWTWOWAY, "To-veis: ")

// Train wait time is either in days or infinite
SETTEXT(LANG_TIMEDAYS, "%d dag(er)")
SETTEXT(LANG_INFINITETIME, "uendelig")

// Shows the load options for ttdload.  %s is the given parameters to be passed to ttdload
SETTEXT(LANG_SWSHOWLOAD, "Trykk en tast for � kj�re \"TTDLOAD %s\" (Escape for � avbryte).")

SETTEXT(LANG_SWABORTLOAD, "\nProgramlasting avbrutt av bruker.\n")


//---------------------------------------
//  STARTUP AND REPORTING
//---------------------------------------

// Internal error in TTDPatch (%d is error number)
SETTEXT(LANG_INTERNALERROR, "*** Intern TTDPatch feil #%d ***\n")

// Error fixing the Windows version HDPath registry entry
SETTEXT(LANG_REGISTRYERROR, "TTD er ikke installert skikkelig (registerfeil %d)\n")

// DOS reports no memory available
SETTEXT(LANG_NOTENOUGHMEM, "Ikke nok minne tilgjengelig %s, trenger %d KB til.\n")

// ...for starting TTD
SETTEXT(LANG_TOSTARTTTD, "for � starte TTD")

// Protected mode code exceeds 32kb
SETTEXT(LANG_PROTECTEDTOOLARGE, "Koden for beskyttet modus er for stor!\n")

// Show where the code was stored, %p is the location
SETTEXT(LANG_CODESTOREDAT, "Koden for beskyttet modus er lagret i %lX.\n")

// Swapping TTDPatch out
SETTEXT(LANG_SWAPPING, "Veksler ut.\n")

// Just before running ttdload, show this.
// 1st %s is ttdload.ovl, then %s is a space if there are options,
// and the 2nd %s contains the options
SETTEXT(LANG_RUNTTDLOAD, "Starter %s%s%s\n")

// Error executing ttdload.  1st %s is ttdload.ovl, 2nd %s is the error message from the OS
SETTEXT(LANG_RUNERROR, "Kunne ikke kj�re %s: %s\n")

// Show the result after after running, %s is one of the following strings
SETTEXT(LANG_RUNRESULT, "Resultat: [%s]\n")
SETTEXT(LANG_RUNRESULTOK, "OK")
SETTEXT(LANG_RUNRESULTERROR, "Feil!")

// Messages about the graphics file ttdpatch.grf
SETTEXT(LANG_NOTTDPATCHGRF, "Kunne ikke finne patchgrafikken %s, lager en tom fil.\n")
SETTEXT(LANG_ERRORCREATING, "Kunne ikke lage %s: %s\n")

