import { Article } from "./types";
import { sources } from "./sources";

function getSource(id: string) {
  return sources.find((s) => s.id === id)!;
}

export const mockArticles: Article[] = [
  {
    id: "1",
    title: "Mbappé buteur lors de la victoire du Real Madrid face à l'Atlético (3-1)",
    link: "#",
    description:
      "Kylian Mbappé a inscrit un doublé lors du derby madrilène. Le Français confirme sa montée en puissance depuis janvier.",
    pubDate: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
    source: getSource("marca"),
    imageUrl: undefined,
  },
  {
    id: "2",
    title: "Transferts : le PSG cible un défenseur central de Serie A",
    link: "#",
    description:
      "Selon nos informations, le Paris Saint-Germain aurait entamé des discussions pour recruter un international italien évoluant en Serie A.",
    pubDate: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
    source: getSource("lequipe"),
  },
  {
    id: "3",
    title: "HERE WE GO! Lamine Yamal prolonge au Barça jusqu'en 2030",
    link: "#",
    description:
      "Accord total entre le FC Barcelone et Lamine Yamal pour une prolongation. Contrat jusqu'en 2030 avec clause libératoire d'un milliard d'euros.",
    pubDate: new Date(Date.now() - 1000 * 60 * 90).toISOString(),
    source: getSource("fabrizio-romano"),
  },
  {
    id: "4",
    title: "Premier League: Arsenal maintain title push with comfortable win",
    link: "#",
    description:
      "Arsenal secured a crucial three points in the Premier League title race with a dominant performance at the Emirates.",
    pubDate: new Date(Date.now() - 1000 * 60 * 120).toISOString(),
    source: getSource("bbc"),
  },
  {
    id: "5",
    title: "Sky Sources: Manchester United in talks for €80m striker",
    link: "#",
    description:
      "Manchester United are in advanced talks to sign a prolific striker, Sky Sports News understands. Personal terms are being discussed.",
    pubDate: new Date(Date.now() - 1000 * 60 * 180).toISOString(),
    source: getSource("skysports"),
  },
  {
    id: "6",
    title: "EXCLUSIVA: el Barça prepara una oferta por un centrocampista del City",
    link: "#",
    description:
      "El FC Barcelona está trabajando en una oferta para hacerse con los servicios de un centrocampista del Manchester City para la próxima temporada.",
    pubDate: new Date(Date.now() - 1000 * 60 * 240).toISOString(),
    source: getSource("sport"),
  },
  {
    id: "7",
    title: "SHOCK MOVE: Liverpool star set for sensational switch to rivals!",
    link: "#",
    description:
      "A Liverpool fan favourite could be on his way to a Premier League rival in a shock transfer that would rock Anfield.",
    pubDate: new Date(Date.now() - 1000 * 60 * 300).toISOString(),
    source: getSource("the-sun"),
  },
  {
    id: "8",
    title: "Napoli-Inter: Conte prepara la sfida scudetto",
    link: "#",
    description:
      "Antonio Conte ha parlato in conferenza stampa alla vigilia del big match contro l'Inter. Sfida decisiva per lo scudetto.",
    pubDate: new Date(Date.now() - 1000 * 60 * 360).toISOString(),
    source: getSource("gazzetta"),
  },
  {
    id: "9",
    title: "Bundesliga-Vorschau: Bayern empfängt Dortmund zum Topspiel",
    link: "#",
    description:
      "Der Klassiker steht an. Bayern München empfängt Borussia Dortmund zum Bundesliga-Topspiel am Samstagabend.",
    pubDate: new Date(Date.now() - 1000 * 60 * 420).toISOString(),
    source: getSource("kicker"),
  },
  {
    id: "10",
    title: "El Real Madrid quiere blindar a Bellingham con un nuevo contrato",
    link: "#",
    description:
      "El conjunto blanco planea ofrecer una mejora de contrato a Jude Bellingham tras su gran rendimiento esta temporada.",
    pubDate: new Date(Date.now() - 1000 * 60 * 480).toISOString(),
    source: getSource("mundodeportivo"),
  },
];
