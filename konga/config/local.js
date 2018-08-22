/**
 * Created by pang on 7/10/2016.
 */
'use strict';
var fs = require('fs');
/**
 * Local environment settings
 *
 * While you're DEVELOPING your app, this config file should include
 * any settings specifically for your development computer (db passwords, etc.)
 *
 * When you're ready to deploy your app in PRODUCTION, you can always use this file
 * for configuration options specific to the server where the app will be deployed.
 * But environment variables are usually the best way to handle production settings.
 *
 * PLEASE NOTE:
 *      This file is included in your .gitignore, so if you're using git
 *      as a version control solution for your Sails app, keep in mind that
 *      this file won't be committed to your repository!
 *
 *      Good news is, that means you can specify configuration for your local
 *      machine in this file without inadvertently committing personal information
 *      (like database passwords) to the repo.  Plus, this prevents other members
 *      of your team from committing their local configuration changes on top of yours.
 *
 * For more information, check out:
 * http://links.sailsjs.org/docs/config/local
 */
module.exports = {

  /**
   * The default fallback URL to Kong's admin API.
   */
  kong_admin_url: process.env.KONG_ADMIN_URL || 'http://gluu.local.org:8001',


  connections: {
    postgres: {
      adapter: 'sails-postgresql',
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'admin',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_DATABASE || 'konga',
      poolSize: process.env.DB_POOLSIZE || 10,
      ssl: process.env.DB_SSL || false
    }
  },

  models: {
    connection: process.env.DB_ADAPTER || 'postgres',
  },

  session: {
    secret: '' // Add your own SECRET string here
  },

  ssl: {
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
  },

  port: process.env.PORT || 1338,
  environment: 'development',
  log: {
    level: 'info'
  },
  oxdWeb: 'http://localhost:8553',
  opHost: 'https://gluu.local.org',
  oxdId: '2f83d8b9-9a27-430e-8eb3-6e4f5d6ba337',
  oxdServerLicenseId: 'e5c1bfd2-3306-4c9e-a49d-983f47454752',
  clientIdOfOXDId: '@!443A.4EBD.9838.15E3!0001!FF43.663E!0008!DB3E.3D96.23FB.060C',
  setupClientOXDId: '2f904d9c-688c-4118-9a17-d471ea3c1315',
  clientId: '@!443A.4EBD.9838.15E3!0001!FF43.663E!0008!192E.EC6E.16B1.DEC9',
  clientSecret: 'f2b5cc6d-9d33-48f3-b5b1-888e23b50093',
  oxdVersion: '3.1.4'
};
