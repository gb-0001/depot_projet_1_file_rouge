from flask import render_template

# Liste des menus
menu_list = [
    {"name": "Accueil", "isActive": "", "url": "index"},
    {"name": "Jouer", "isActive": "", "url": "game"},
    {"name": "Mode", "isActive": "", "url": "mode"},
    {"name": "Sujet", "isActive": "", "url": "subject"},
    {"name": "Question", "isActive": "", "url": "question"},
    {"name": "Réponse", "isActive": "", "url": "answer"},
    {"name": "Utilisateur", "isActive": "", "url": "user"}
]


   @app.route('/')
   def index():

      app.logger.info('index.html')
      return render_template('index.html',menu_list=menu_list )
