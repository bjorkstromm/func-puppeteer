import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import * as Puppeteer from 'puppeteer';

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('HTTP trigger function processed a request.');

    const browser = await Puppeteer.launch({
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox"
        ]
      });

    const page = await browser.newPage();
    await page.goto('https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-function-linux-custom-image', {"waitUntil" : "networkidle0"});

    const pdf = await page.pdf({format: 'A4'});
    await browser.close();

    context.res = {
        headers: {
          "Content-Type": "application/octet-stream"
        },
        body: pdf
      };

};

export default httpTrigger;