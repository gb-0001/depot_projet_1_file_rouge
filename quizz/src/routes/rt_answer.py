import json
from models.quizz.answer import Answer
from flask import render_template,request, redirect, url_for
from config.env import baseUrl
import requests

url = '/api/v1/answer' 
   
# Liste des menus
menu_list=[
         {"name":"Accueil","isActive":"","url":"home"},
         {"name":"Mode","isActive":"","url":"mode"},
         {"name":"Sujet","isActive":"","url":"subject"},
         {"name":"Question","isActive":"","url":"question"},
         {"name":"Réponse","isActive":"active","url":"answer"},
         {"name": "Utilisateur", "isActive": "", "url": "listuser"}
      ]

tableInfo={
   "headers":[
      {"name":"answer","display":"Réponse","class":""}
   ],
   "actions":[
      {"icon":"fa-pen-square","class":"","url":"update_answer"},
      {"icon":"fa-trash-alt","class":"btn-icon-danger","url":"delete_answer"}
   ]
}

def configure_routes_answer(app):

   @app.route('/answer')
   def answer():
      
      rep_list = requests.get(baseUrl+url).json()
      rep_list = json.loads(rep_list)

      return render_template('quizz/answer/index.html',
      tableInfo=tableInfo,
      menu_list=menu_list, 
      rep_list=rep_list)

   @app.route('/answer/create',methods=['GET', 'POST'])
   def create_answer():

      # Rendu de la page de création
      if request.method == "GET":
         return render_template('quizz/answer/create.html',menu_list=menu_list,answer=None)  
      
      # Soumission du formulaire
      if request.method == "POST":
         answer = {
            'answer':request.form.get('answer'),
         }
         requests.post(baseUrl+url,json.dumps(answer))
         return redirect(url_for("answer")) 
   
   @app.route('/answer/update/<id>',methods=['GET', 'POST'])
   def update_answer(id): 

      # Mise à jour de l'url
      newurl = baseUrl+url+'/'+str(id)

      # Rendu de la page de modification
      if request.method == "GET":
         answer = requests.get(newurl).json()
         return render_template('quizz/answer/update.html',menu_list=menu_list,answer=answer)
      
      # Soumission du formulaire
      if request.method == "POST":
         answer = {
            'answer':request.form.get('answer'),
         }
         requests.put(newurl,json.dumps(answer))
         return redirect(url_for("answer")) 


   @app.route('/answer/delete/<id>',methods=['GET', 'POST'])
   def delete_answer(id): 
   
      # Mise à jour de l'url
      newurl = baseUrl+url+'/'+str(id)

      # Rendu de la page de suppression
      if request.method == "GET":
         answer = requests.get(newurl).json()
         return render_template('quizz/answer/delete.html',menu_list=menu_list,answer=answer)

      # Soumission du formulaire
      if request.method == "POST":
         requests.delete(newurl)
         return redirect(url_for("answer")) 

   
