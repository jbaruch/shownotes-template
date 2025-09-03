const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  // Listen for console errors
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('CONSOLE ERROR:', msg.text());
    }
  });
  
  // Listen for network failures
  page.on('response', response => {
    if (!response.ok() && response.url().includes('googleusercontent')) {
      console.log('FAILED REQUEST:', response.url(), response.status());
    }
  });
  
  await page.goto('http://localhost:4000/');
  await page.waitForTimeout(3000);
  
  // Check for broken images
  const brokenImages = await page.evaluate(() => {
    const images = Array.from(document.querySelectorAll('img.preview-image'));
    return images.filter(img => !img.complete || img.naturalWidth === 0).map(img => ({
      src: img.src,
      alt: img.alt,
      complete: img.complete,
      naturalWidth: img.naturalWidth
    }));
  });
  
  console.log('BROKEN IMAGES:', JSON.stringify(brokenImages, null, 2));
  
  await browser.close();
})();
