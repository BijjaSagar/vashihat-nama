FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json ./
RUN npm install

# Bundle app source
COPY . .

# Expose port 8080
EXPOSE 8080

# Start command
CMD [ "node", "index.js" ]
