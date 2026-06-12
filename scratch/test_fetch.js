async function main() {
  try {
    const res = await fetch("https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/stations.json");
    if (!res.ok) throw new Error("HTTP " + res.status);
    const data = await res.json();
    console.log("Success! Found", data.length, "stations in stations.json");
  } catch (e) {
    console.error("Fetch failed:", e);
  }
}
main();
