# Base copied from https://hub.docker.com/r/estruyf/azure-function-node-puppeteer/dockerfile
FROM mcr.microsoft.com/azure-functions/node:3.0 as base

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# It's a good idea to use dumb-init to help prevent zombie chrome processes.
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init
ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost"]

# Define required envvars
ENV AzureWebJobsScriptRoot=/home/site/wwwroot

FROM mcr.microsoft.com/azure-functions/node:3.0-node10 as build

WORKDIR /src/build
COPY . .
RUN ls -la
RUN pwd
RUN ["npm", "i"]
RUN ["npm", "run", "build:production"]

FROM base as final
WORKDIR /home/site/wwwroot
RUN ls -la
COPY --from=build /src/build/host.json ./host.json
COPY --from=build /src/build/Generate/function.json ./Generate/function.json
COPY --from=build /src/build/node_modules ./node_modules
COPY --from=build /src/build/dist ./dist