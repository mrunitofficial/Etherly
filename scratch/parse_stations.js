const fs = require('fs');
try {
  const data = JSON.parse(fs.readFileSync('/home/marijnluijten/.gemini/antigravity-ide/brain/1c637819-0b55-4fea-9c7b-b6304ae68c8e/.system_generated/steps/28/output.txt', 'utf8'));
  console.log("Found", data.documents.length, "documents!");
} catch (e) {
  console.error("Read failed:", e.message);
}
