# -*- coding: utf-8 -*-
from flask import Flask, sessions,render_template
from flask_sqlalchemy import SQLAlchemy
from os import path
from flask_login import LoginManager
from flask_cors import CORS


db = SQLAlchemy()
DB_NAME = 'database.db'

def create_app():
    app = Flask(__name__)

    CORS(app)

    app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://user.quizz:dru98eDFC90@localhost/db.quizz'
    db.init_app(app)

    from .controllers.user import users
    from .controllers.auth import auths
    from .controllers.question import questions
    from .controllers.qcm import qcms
    from .controllers.qcm_session import qcm_sessions
    from .controllers.client import client


    app.register_blueprint(client,url_prefix='/')
    app.register_blueprint(users,url_prefix='/api/user')
    app.register_blueprint(auths,url_prefix='/api/auth')
    app.register_blueprint(questions,url_prefix='/api/question')
    app.register_blueprint(qcms,url_prefix='/api/qcm')
    app.register_blueprint(qcm_sessions,url_prefix='/api/qcm-session')

    from .models import User,Qcm,QcmQuestion,Question

    create_database(app)

    @app.errorhandler(404)
    def not_found(e):
        return render_template("index.html")

    return app

def create_database(app):
    db.create_all(app=app)
    print('Created DataBase!')



