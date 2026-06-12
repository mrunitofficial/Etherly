const fs = require('fs');
const path = require('path');

// GitHub files collected via MCP
const githubFiles = [
  "100p/100P90s&00s.png", "100p/100p70s&80s.png", "100p/100pFeest.png", "100p/100pNonStop.png", "100p/100pRadio.png",
  "538/538 90's.png", "538/538 Dance Department.png", "538/538 Greatest Hits.png", "538/538 Hitzone.png", "538/538 Ibiza.png", "538/538 Non-Stop.png", "538/538 Party.png", "538/538 Radio.png", "538/538 Top 50.png", "538/538 Zomer.png",
  "Arrow/Arrow Bluesbox.png", "Arrow/Arrow CAZ!.png", "Arrow/Arrow Classic Rock.png",
  "BNR/BNR Business Beats.png", "BNR/BNR Nieuwsradio.png",
  "Classicnl/Classicnl Mind Radio.png", "Classicnl/Classicnl Opera.png", "Classicnl/Classicnl Radio.png", "Classicnl/Classicnl Soundtracks.png",
  "FunX/FunX Afro.png", "FunX/FunX Amsterdam.png", "FunX/FunX Arab.png", "FunX/FunX Den Haag.png", "FunX/FunX Fissa.png", "FunX/FunX Hiphop.png", "FunX/FunX Latin.png", "FunX/FunX NL.png", "FunX/FunX Rotterdam.png", "FunX/FunX Slowjamz.png", "FunX/FunX Utrecht.png",
  "Joe België/Joe België 80s & 90s.png", "Joe België/Joe België Christmas.png", "Joe België/Joe België Easy.png", "Joe België/Joe België Gold.png", "Joe België/Joe België Lage landen.png", "Joe België/Joe België Top 2000.png", "Joe België/Joe België.png",
  "Joe/Joe Non-stop.png", "Joe/Joe.png",
  "Jumbo/Jumbo Radio.png",
  "KINK/KINK 80's.png", "KINK/KINK 90's.png", "KINK/KINK Distortion.png", "KINK/KINK No Alternative.png", "KINK/KINK.png",
  "Lokale Omroepen/Omroep Brabant.png",
  "Nostalgie/Nostalgie.png",
  "NPO/NPO 3FM.png", "NPO/NPO Blend.png", "NPO/NPO Campus Radio.png", "NPO/NPO Klassiek.png", "NPO/NPO Radio 1.png", "NPO/NPO Radio 2.png", "NPO/NPO Radio 5.png", "NPO/NPO Soul & Jazz.png", "NPO/NPO Sterren NL.png",
  "Q-dance Radio/Q-dance Radio.png",
  "Qmusic/Qmusic 90s & 00s.png", "Qmusic/Qmusic Het Foute Uur.png", "Qmusic/Qmusic Nederlandstalig.png", "Qmusic/Qmusic Non-stop.png", "Qmusic/Qmusic Themazender.png", "Qmusic/Qmusic Top 40.png", "Qmusic/Qmusic.png",
  "Radio 10/Radio 10 60's & 70's Hits.png", "Radio 10/Radio 10 80's Hits.png", "Radio 10/Radio 10 90's Hits.png", "Radio 10/Radio 10 Disco Classics.png", "Radio 10/Radio 10 Love Songs.png", "Radio 10/Radio 10 Non-Stop.png", "Radio 10/Radio 10 Top 4000.png", "Radio 10/Radio 10.png",
  "Radio Noordzee/Radio Noordzee.png",
  "SLAM!/SLAM! '00s.png", "SLAM!/SLAM! '10s.png", "SLAM!/SLAM! '90's.png", "SLAM!/SLAM! Housuh in de Pauzuh.png", "SLAM!/SLAM! Juize.png", "SLAM!/SLAM! Mixmarathon.png", "SLAM!/SLAM! Non-Stop.png", "SLAM!/SLAM! The Boom Room.png", "SLAM!/SLAM! WKNDMX.png", "SLAM!/SLAM!.png",
  "Sky/Sky 00's & 10's.png", "Sky/Sky 80's Hits.png", "Sky/Sky @Work.png", "Sky/Sky Christmas.png", "Sky/Sky Hits.png", "Sky/Sky Love Songs.png", "Sky/Sky Radio Non Stop.png", "Sky/Sky Radio.png", "Sky/Sky Smooth Hits.png", "Sky/Sky Summer Hits.png", "Sky/Sky Top 1000.png",
  "Studio Brussel/Studio Brussel.png",
  "Sublime/Sublime Jazz.png", "Sublime/Sublime R&B '90s & '00s.png", "Sublime/Sublime Soul Classics.png", "Sublime/Sublime Sunday Chill.png", "Sublime/Sublime.png",
  "Sunlite Radio/Sunlite Radio.png",
  "Tomorrowland/Daybreak Sessions.png", "Tomorrowland/One World Radio.png", "Tomorrowland/Tomorrowland Anthems.png",
  "Veronica/Radio Veronica.png", "Veronica/Veronica Goud van Oud.png", "Veronica/Veronica Non-stop.png", "Veronica/Veronica Rock Radio.png", "Veronica/Veronica Top 3000.png",
  "Yoursafe Radio/Yoursafe Radio.png"
];

// Firestore stations collected via MCP
const firestoreStations = [
  { id: "0UZ9fPcYfSNuuwUHeJp6", name: "Sky Love Songs", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Love%20Songs.png" },
  { id: "0e0T0idBQdGGqAybQRJv", name: "Joe", category: "Joe", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe/Joe.png" },
  { id: "1y1PHapKBJih25YGz8GK", name: "SLAM! Mixmarathon", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20Mixmarathon.png" },
  { id: "2EOIUEQ8gLQk3Jxoeln8", name: "100% NL Feest", category: "100% NL", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/100p/100pFeest.png" },
  { id: "45k7flT2qrjWboN9C0kq", name: "Daybreak Sessions", category: "Tomorrowland", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Tomorrowland/Daybreak%20Sessions.png" },
  { id: "4DPL1sdGcHgdqDHmClYm", name: "Sublime Soul Classics", category: "Sublime", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sublime/Sublime%20Soul%20Classics.png" },
  { id: "5hAFKmyCjYZ1HWf6UiQL", name: "NPO Sterren NL", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Sterren%20NL.png" },
  { id: "6O9FVCske2VAEY6FPEyI", name: "NPO Soul & Jazz", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Soul%20%26%20Jazz.png" },
  { id: "6wh5trpDMdVQq1ihKUG0", name: "538 90's", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%2090's.png" },
  { id: "7A81MT6Q4wQug0NDtgAF", name: "Classicnl Opera", category: "Classicnl", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Classicnl/Classicnl%20Opera.png" },
  { id: "7RyMJdxT1canB1bk0dlF", name: "FunX NL", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20NL.png" },
  { id: "7qf3M6Hm7JCphZbssS3G", name: "538 Non-Stop", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Non-Stop.png" },
  { id: "8BvnXPrOdFkBz1ueAARu", name: "538 Greatest hits", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Greatest%20Hits.png" },
  { id: "8VSGpsgPb1qslZdv7kqX", name: "Sky Smooth Hits", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Smooth%20Hits.png" },
  { id: "973SYrd5P7bFUHxZi2tr", name: "Q-dance Radio", category: "Q-dance Radio", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Q-dance%20Radio/Q-dance%20Radio.png" },
  { id: "A3FLmEQZ0RAu6qwJ3cKN", name: "538 Dance Department", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Dance%20Department.png" },
  { id: "Aomo7PKL9ExV0uXkCXRu", name: "FunX Afro", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Afro.png" },
  { id: "AuOyGDKWK0QMrr2C0V13", name: "FunX Arab", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Arab.png" },
  { id: "AxFpp2LYbjXVAGLuwkoV", name: "BNR Business Beats", category: "BNR", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/BNR/BNR%20Business%20Beats.png" },
  { id: "BRTip4aU7JTr41SQDJhB", name: "Radio 10 Non-Stop", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%20Non-Stop.png" },
  { id: "BTe1uanazYqhfsQm6fE9", name: "Joe België Lage landen", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%20Lage%20landen.png" },
  { id: "CMw0ue85KL1iwxCzy9hZ", name: "FunX Fissa", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Fissa.png" },
  { id: "CfJeviYpmend409WEpKN", name: "Radio 10 90s Hits", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%2090's%20Hits.png" },
  { id: "CqK9I3pOAKYvXfq6RC8y", name: "100% NL", category: "100% NL", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/100p/100pRadio.png" },
  { id: "DAoPs19g8mRGtwa1nPxG", name: "NPO Klassiek", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Klassiek.png" },
  { id: "DSN6T6LShSDU4ld0sLwv", name: "Joe België Easy", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%20Easy.png" },
  { id: "DXSYWUZwNAqyji7rbGTL", name: "Yoursafe Radio", category: "Yoursafe Radio", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Yoursafe%20Radio/Yoursafe%20Radio.png" },
  { id: "EAFANqdprdOqhzDd6qkg", name: "Studio Brussel", category: "Studio Brussel", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Studio%20Brussel/Studio%20Brussel.png" },
  { id: "EP8V63zZhFgNQP0ts3om", name: "Sublime R&B '90s & '00s", category: "Sublime", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sublime/Sublime%20R%26B%20'90s%20%26%20'00s.png" },
  { id: "FOjHRNLDZiXBa2aQZ9yb", name: "Radio Noordzee", category: "Radio Noordzee", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%20Noordzee/Radio%20Noordzee.png" },
  { id: "FfiIN86iIaNE6GLPpD1J", name: "Classicnl", category: "Classicnl", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Classicnl/Classicnl%20Radio.png" },
  { id: "FrX8PxS4Vf7fP3uBSMAV", name: "538 Top 50", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Top%2050.png" },
  { id: "GC6NUqY64WUnhHqiNZi0", name: "SLAM! Juize", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20Juize.png" },
  { id: "GiK7v1mCChs8eqN3fAgD", name: "Sublime Jazz", category: "Sublime", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sublime/Sublime%20Jazz.png" },
  { id: "HJhCEoaJAaLfpABbpGNe", name: "SLAM! WKNDMX", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20WKNDMX.png" },
  { id: "ITn1YkMHAmxVA06lESx0", name: "Radio Veronica", category: "Veronica", art: "https://firebasestorage.googleapis.com/v0/b/etherly-firebase.firebasestorage.app/o/art%2FRadio%20Veronica%2FITn1YkMHAmxVA06lESx0.png?alt=media&token=a8ba83fd-dc40-4e4c-a8b7-81fd4e8a70b5" },
  { id: "IX5IIbSYixpHz9wAFylU", name: "Sky Summer Hits", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Summer%20Hits.png" },
  { id: "JBEpd6XcfSQ0xYdkpj2s", name: "Qmusic Top 40", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic%20Top%2040.png" },
  { id: "JM3xBhoIiUxzkDbVT38Y", name: "Sky 00's & 10's", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%2000's%20%26%2010's.png" },
  { id: "JNwkDn00HV6kVyUGd5Yd", name: "SLAM! Non-Stop", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20Non-Stop.png" },
  { id: "JdI9sS7haha7GLYvgmar", name: "FunX Den Haag", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Den%20Haag.png" },
  { id: "JkmOU8PpFvJ0JBuzDH3g", name: "Classicnl Soundtracks", category: "Classicnl", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Classicnl/Classicnl%20Soundtracks.png" },
  { id: "KIUV6aAlA8FyT2VTHYQK", name: "KINK Distortion", category: "KINK", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/KINK/KINK%20Distortion.png" },
  { id: "LC1F0y7I4mvPJ0hbKSIp", name: "FunX Amsterdam", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Amsterdam.png" },
  { id: "LJYVGFglrojeGG2602fl", name: "FunX Latin", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Latin.png" },
  { id: "LnADsxby56qNNbQFFVvJ", name: "One World Radio", category: "Tomorrowland", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Tomorrowland/One%20World%20Radio.png" },
  { id: "MCSro4fz7gHsuT6iMTiI", name: "538 Hitzone", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Hitzone.png" },
  { id: "NNhi4UQ6u0PbEnjjWFe8", name: "Joe België Christmas", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%20Christmas.png" },
  { id: "ObNaSCGFusyS0dk8NzyD", name: "538 Zomer", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Zomer.png" },
  { id: "Ot4fMM3mmbTwZVXtqBd8", name: "Radio 10 60's & 70's Hits", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%2060's%20%26%2070's%20Hits.png" },
  { id: "PBHlRsWfqG9h9wz6QBJi", name: "NPO 3FM", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%203FM.png" },
  { id: "PN3fj5Ww41lqhaY0BKde", name: "Qmusic Het Foute Uur", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic%20Het%20Foute%20Uur.png" },
  { id: "PV6puUGrwsolUCjcDBH8", name: "Sunlite Radio", category: "Sunlite Radio", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sunlite%20Radio/Sunlite%20Radio.png" },
  { id: "Q8EJQ4pdGcPgn2OQBj3b", name: "SLAM! '10s", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20'10s.png" },
  { id: "R7aiAsVR7CTaEmA5o3zd", name: "NPO Radio 5", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Radio%205.png" },
  { id: "RToGNwuP9YuD2kseMaBL", name: "Qmusic Nederlandstalig", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic%20Nederlandstalig.png" },
  { id: "RZhcUXiNCdmHoZxyzO0K", name: "Sky Radio", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Radio.png" },
  { id: "Tq0jGservBIvUpTtW1iQ", name: "Veronica Goud van Oud", category: "Veronica", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Veronica/Veronica%20Goud%20van%20Oud.png" },
  { id: "U1burAAtKnubg9HeRuYe", name: "Sky Hits", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Hits.png" },
  { id: "U9nDxiu2YSZs0z4gtoYA", name: "NPO Radio 2", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Radio%202.png" },
  { id: "VVCCWAwhDPGDdPfrTf7f", name: "Sky 80's Hits", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%2080's%20Hits.png" },
  { id: "Ve8hYRjjcHeRvQqhDoqu", name: "538 Party", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Party.png" },
  { id: "X3CKM46k4OCAevheP8DK", name: "Omroep Brabant", category: "Lokale Omroepen", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Lokale%20Omroepen/Omroep%20Brabant.png" },
  { id: "XrWtUDPtshcl6s1TUTpY", name: "FunX Rotterdam", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Rotterdam.png" },
  { id: "Y1fzSUNqWJKnhFUp1Ftv", name: "KINK", category: "KINK", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/KINK/KINK.png" },
  { id: "YEg9oxgywDiA2i5y2Lwr", name: "Veronica Rock Radio", category: "Veronica", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Veronica/Veronica%20Rock%20Radio.png" },
  { id: "ZHcbKTo62tqEmg6cDRWx", name: "Joe Non-stop", category: "Joe", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe/Joe%20Non-stop.png" },
  { id: "ZLdqPVrZhGJAgKQkUSwd", name: "Radio 10 80s Hits", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%2080's%20Hits.png" },
  { id: "aPJFN4HFmXzVf0r4JkG4", name: "BNR Nieuwsradio", category: "BNR", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/BNR/BNR%20Nieuwsradio.png" },
  { id: "aXGjA1rYtI8VpN7ayQz7", name: "SLAM! Housuh in de Pauzuh", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20Housuh%20in%20de%20Pauzuh.png" },
  { id: "acdoK08itIzUcF28QDpO", name: "Arrow Classic Rock", category: "Arrow", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Arrow/Arrow%20Classic%20Rock.png" },
  { id: "bI9WOg6aDvefBAoPbOYU", name: "Veronica Non-stop", category: "Veronica", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Veronica/Veronica%20Non-stop.png" },
  { id: "cSUHqnCobO8tVAw87aWI", name: "NPO Radio 1", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Radio%201.png" },
  { id: "cehuvpb5m4pDrcimsQam", name: "100% NL Non-Stop", category: "100% NL", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/100p/100pNonStop.png" },
  { id: "cnXsNnKtrqRLBs7YAAxO", name: "Joe België", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB.png" },
  { id: "dC4CtJ40qADBZKelpHKZ", name: "FunX Hiphop", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Hiphop.png" },
  { id: "eSTn6sItOhzPu27dKo5m", name: "Arrow Bluesbox", category: "Arrow", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Arrow/Arrow%20Bluesbox.png" },
  { id: "eipC65yA9C78G3t86ofJ", name: "SLAM! '00s", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20'00s.png" },
  { id: "fG8Oj0vcztk7R9jQnzpv", name: "Sky @Work", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20@Work.png" },
  { id: "fHWdBaPzrsnJFOqIdIga", name: "Joe België 80s & 90s", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%2080s%20%26%2090s.png" },
  { id: "uYrXzvPbQ5OQr8OM044M", name: "100% NL 90's & 00's", category: "100% NL", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/100p/100P90s%2600s.png" },
  { id: "vTKBqdcPy14tCVOCCRkV", name: "NPO Blend", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Blend.png" },
  { id: "vdkADW0RuVzFkHiCGVzh", name: "Tomorrowland Anthems", category: "Tomorrowland", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Tomorrowland/Tomorrowland%20Anthems.png" },
  { id: "vuXxcntAlyw3ad2WjzF5", name: "Sky Christmas", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Christmas.png" },
  { id: "w4knoH4zWVxDII1bkDQC", name: "FunX Utrecht", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Utrecht.png" },
  { id: "w7XKHcKFkT85odEKfh9o", name: "Qmusic Non-stop", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic%20Non-stop.png" },
  { id: "xPDsL3uLjRawjgUUa5Uk", name: "SLAM! The Boom Room", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20The%20Boom%20Room.png" },
  { id: "xeKM6DKKYjqR12O9rOx0", name: "100% NL 70's & 80's", category: "100% NL", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/100p/100p70s%2680s.png" },
  { id: "xsbqniiysoMWG3FuNJ4A", name: "Sublime", category: "Sublime", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sublime/Sublime.png" },
  { id: "xxgAO60u5tb3QkZ6dInk", name: "Joe België Gold", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%20Gold.png" },
  { id: "yokUBWzVd4adsa5qDkzN", name: "Sublime Sunday Chill", category: "Sublime", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sublime/Sublime%20Sunday%20Chill.png" },
  { id: "zHP9xL6NR4XtQjAc0HZd", name: "NPO Campus Radio", category: "NPO", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/NPO/NPO%20Campus%20Radio.png" },
  { id: "zJeHy5hOWMgPECVx8HQt", name: "Veronica Top 3000", category: "Veronica", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Veronica/Veronica%20Top%203000.png" },
  { id: "zso5skr4H1nJ6rrsCVCu", name: "Qmusic", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic.png" },
  
  // From Chunk 6 and Chunk 7 matching:
  { id: "fLd2YrPxqmm1sCCEFr6H", name: "Nostalgie", category: "Nostalgie", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Nostalgie/Nostalgie.png" },
  { id: "frGXcqfYte9NLMX9Y5QB", name: "Jumbo Radio", category: "Jumbo", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Jumbo/Jumbo%20Radio.png" },
  { id: "hUhIFtJyCbWAH9iq2LTC", name: "KINK No Alternative", category: "KINK", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/KINK/KINK%20No%20Alternative.png" },
  { id: "iAmdoNcxL4NZarnhsASz", name: "SLAM!", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!.png" },
  { id: "jv0QYDsFaSh2y91tdeAX", name: "538 Ibiza", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Ibiza.png" },
  { id: "kFsL762MocC9al1eqmXH", name: "Radio 10 Disco Classics", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%20Disco%20Classics.png" },
  { id: "mNQZSaSEsoomnoEOAEwR", name: "SLAM! '90s", category: "SLAM!", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/SLAM!/SLAM!%20'90's.png" },
  { id: "mhkrTGYemZRieszY1u6x", name: "Qmusic Themazender", category: "Qmusic", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Qmusic/Qmusic%20Themazender.png" },
  { id: "nPxZ0ystDduCgjsL2GqV", name: "KINK 90's", category: "KINK", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/KINK/KINK%2090's.png" },
  { id: "nZL4w8srrjWnhEbs1Rlc", name: "Radio 10 Top 4000", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%20Top%204000.png" },
  { id: "nihPpkGsYu5nUPUHTaoD", name: "Sky Radio Non Stop", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Radio%20Non%20Stop.png" },
  { id: "oQMgf906YdMfNLidR5dY", name: "Arrow CAZ!", category: "Arrow", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Arrow/Arrow%20CAZ!.png" },
  { id: "okfGurqB03SZ7XQEY6iz", name: "FunX Slowjamz", category: "FunX", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/FunX/FunX%20Slowjamz.png" },
  { id: "saJf8DsImMk8nyVdSNLi", name: "Sky Top 1000", category: "Sky", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Sky/Sky%20Top%201000.png" },
  { id: "t1lfk7sXjy1MsaL97OPr", name: "Classicnl Mind Radio", category: "Classicnl", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Classicnl/Classicnl%20Mind%20Radio.png" },
  { id: "t4JyrRrRxz85vxLC8d6P", name: "Radio 10", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010.png" },
  { id: "tViWLOXn4ydwbRZuU5Vo", name: "Radio 538", category: "538", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/538/538%20Radio.png" },
  { id: "tXOSQP9XRMn7xg2r2dF3", name: "Joe België Top 2000", category: "Joe België", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Joe%20Belgi%C3%AB/Joe%20Belgi%C3%AB%20Top%202000.png" },
  { id: "toClRramMCvbwZXO3LVM", name: "Radio 10 Love Songs", category: "Radio 10", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/Radio%2010/Radio%2010%20Love%20Songs.png" },
  { id: "u7v1Kl6IPUyls6rfT6FX", name: "KINK 80's", category: "KINK", art: "https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/KINK/KINK%2080's.png" }
];

function cleanName(name) {
  // strip all characters except letters, digits, & and !
  return name.replace(/[^a-zA-Z0-9&!]/g, '');
}

function run() {
  const map = {};
  const matchedFiles = new Set();
  const matchedStations = new Set();

  // Helper to extract sanitized filename from URL or path
  function getSanitizedFilename(filePathOrUrl) {
    const decoded = decodeURIComponent(filePathOrUrl);
    const filenameWithExt = path.basename(decoded.split('?')[0]);
    const filename = filenameWithExt.replace(/\.png$/, '');
    return cleanName(filename);
  }

  // 1. Direct Match by GitHub URL inside Firestore's `art` field
  for (const station of firestoreStations) {
    if (station.art.includes('raw.githubusercontent.com') || station.art.includes('etherly-firebase.firebasestorage.app')) {
      const artSanitized = getSanitizedFilename(station.art);
      
      // Look for a github file that has the same sanitized filename
      const file = githubFiles.find(f => getSanitizedFilename(f) === artSanitized);
      if (file) {
        map[artSanitized] = station.id;
        matchedFiles.add(file);
        matchedStations.add(station.id);
      }
    }
  }

  // 2. Fallback Match: Compare sanitized station name with sanitized GitHub filename
  for (const station of firestoreStations) {
    if (matchedStations.has(station.id)) continue;

    const stationSanitized = cleanName(station.name);
    // Find unmatched github file that has same sanitized filename
    const file = githubFiles.find(f => {
      if (matchedFiles.has(f)) return false;
      return getSanitizedFilename(f) === stationSanitized;
    });

    if (file) {
      const sanitizedKey = getSanitizedFilename(file);
      map[sanitizedKey] = station.id;
      matchedFiles.add(file);
      matchedStations.add(station.id);
    }
  }

  // 3. Fallback Match 2: Compare sanitized category + name
  for (const station of firestoreStations) {
    if (matchedStations.has(station.id)) continue;

    const stationSanitized = cleanName(station.name);
    const file = githubFiles.find(f => {
      if (matchedFiles.has(f)) return false;
      const fn = getSanitizedFilename(f);
      return fn.includes(stationSanitized) || stationSanitized.includes(fn);
    });

    if (file) {
      const sanitizedKey = getSanitizedFilename(file);
      map[sanitizedKey] = station.id;
      matchedFiles.add(file);
      matchedStations.add(station.id);
    }
  }

  // Write static map output
  const rootMapPath = path.join(__dirname, '../station_map.json');
  fs.writeFileSync(rootMapPath, JSON.stringify(map, null, 2), 'utf8');
  console.log(`Successfully generated station_map.json at ${rootMapPath} with ${Object.keys(map).length} mappings.`);

  // Find mismatches
  const unmatchedFiles = githubFiles.filter(f => !matchedFiles.has(f));
  const unmatchedStations = firestoreStations.filter(s => !matchedStations.has(s.id));

  console.log('\n--- UNMATCHED GITHUB FILES ---');
  if (unmatchedFiles.length === 0) {
    console.log('None! All files successfully matched.');
  } else {
    unmatchedFiles.forEach(f => console.log(`- ${f} (Sanitized: ${getSanitizedFilename(f)})`));
  }

  console.log('\n--- UNMATCHED FIRESTORE STATIONS ---');
  if (unmatchedStations.length === 0) {
    console.log('None! All stations successfully matched.');
  } else {
    unmatchedStations.forEach(s => console.log(`- [${s.id}] ${s.name} (art: ${s.art})`));
  }
}

run();
