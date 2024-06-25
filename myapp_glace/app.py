from flask import Flask, render_template, request, redirect, url_for
from pymongo import MongoClient
from bson.objectid import ObjectId

app = Flask(__name__)

# MongoDB Atlas connection
client = MongoClient("mongodb+srv://medleminehaj:22482188@mycluster.j2cqkjb.mongodb.net/myapp?retryWrites=true&w=majority&appName=mycluster")
db = client.myapp

# Collection names
COLLECTION_NAME1 = "Utilisateurs"
COLLECTION_NAME2 = "Client"
COLLECTION_NAME3 = "Demande"
COLLECTION_NAME4 = "Proprietaire"

@app.route('/')
def home():
    return render_template('home.html', title="Accueil")

# Utilisateurs Routes
@app.route('/utilisateurs')
def get_utilisateurs():
    utilisateurs = list(db[COLLECTION_NAME1].find())
    return render_template('utilisateurs.html', utilisateurs=utilisateurs)

@app.route('/utilisateur/<id>')
def get_utilisateur(id):
    utilisateur = db[COLLECTION_NAME1].find_one({'_id': ObjectId(id)})
    return render_template('utilisateur.html', utilisateur=utilisateur)

@app.route('/utilisateur/create', methods=['GET', 'POST'])
def create_utilisateur():
    if request.method == 'POST':
        utilisateur = {
            'email': request.form['email'],
            'pwd': request.form['pwd'],
            'numero': request.form['numero'],
            'type': request.form['type']
        }

        if utilisateur['type'] == 'client':
            # Générer un nouvel ID_Client unique
            dernier_client = db[COLLECTION_NAME2].find_one(sort=[('ID_Client', -1)])
            nouvel_id_client = (dernier_client['ID_Client'] + 1) if dernier_client else 1
            utilisateur['ID_Client'] = nouvel_id_client

            # Insérer le client dans la collection 'Client'
            client = {
                'email': utilisateur['email'],
                'ID_Client': nouvel_id_client,
                'historique': [],
                'nom': request.form['nom'],
                'prenom': request.form['prenom']
            }
            db[COLLECTION_NAME2].insert_one(client)

        elif utilisateur['type'] == 'proprietaire':
            # Générer un nouvel ID_Proprietaire unique
            dernier_proprietaire = db[COLLECTION_NAME4].find_one(sort=[('ID_Proprietaire', -1)])
            nouvel_id_proprietaire = (dernier_proprietaire['ID_Proprietaire'] + 1) if dernier_proprietaire else 1
            utilisateur['ID_Proprietaire'] = nouvel_id_proprietaire

            # Insérer le propriétaire dans la collection 'Proprietaire'
            proprietaire = {
                'email': utilisateur['email'],
                'ID_Proprietaire': nouvel_id_proprietaire,
                'nom': request.form['nom'],
                'prenom': request.form['prenom'],
                'location': request.form['location'],
                'description': request.form['description'],
                'quantite': int(request.form['quantite'])
            }
            db[COLLECTION_NAME4].insert_one(proprietaire)

        # Insérer l'utilisateur dans la collection 'Utilisateurs'
        db[COLLECTION_NAME1].insert_one(utilisateur)
        return redirect(url_for('get_utilisateurs'))
    
    return render_template('create_utilisateur.html')

@app.route('/utilisateur/edit/<id>', methods=['GET', 'POST'])
def edit_utilisateur(id):
    utilisateur = db[COLLECTION_NAME1].find_one({'_id': ObjectId(id)})
    if request.method == 'POST':
        updated_utilisateur = {
            'email': request.form['email'],
            'pwd': request.form['pwd'],
            'numero': request.form['numero'],
        }
        db[COLLECTION_NAME1].update_one({'_id': ObjectId(id)}, {'$set': updated_utilisateur})
        return redirect(url_for('get_utilisateurs'))
    return render_template('edit_utilisateur.html', utilisateur=utilisateur)

@app.route('/utilisateur/delete/<id>')
def delete_utilisateur(id):
    db[COLLECTION_NAME1].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_utilisateurs'))

# Client Routes
@app.route('/clients')
def get_clients():
    clients = list(db[COLLECTION_NAME2].find())
    return render_template('clients.html', clients=clients)

@app.route('/client/<id>')
def get_client(id):
    client = db[COLLECTION_NAME2].find_one({'_id': ObjectId(id)})
    return render_template('client.html', client=client)

@app.route('/client/create', methods=['GET', 'POST'])
def create_client():
    if request.method == 'POST':
        email = request.form['email']
        utilisateur = db[COLLECTION_NAME1].find_one({'email': email, 'type': 'client'})

        if utilisateur:
            client = {
                'email': email,
                'ID_Client': utilisateur['ID_Client'],
                'nom': request.form['nom'],
                'prenom': request.form['prenom']
            }
            db[COLLECTION_NAME2].insert_one(client)
            return redirect(url_for('get_clients'))
        else:
            return "Utilisateur non trouvé ou n'est pas un client", 404

    # Récupérer les emails des utilisateurs de type client
    utilisateurs_clients = list(db[COLLECTION_NAME1].find({'type': 'client'}, {'email': 1, '_id': 0}))
    return render_template('create_client.html', utilisateurs_clients=utilisateurs_clients)

@app.route('/client/edit/<id>', methods=['GET', 'POST'])
def edit_client(id):
    client = db[COLLECTION_NAME2].find_one({'_id': ObjectId(id)})
    if not client:
        return "Client non trouvé", 404

    if request.method == 'POST':
        email = request.form['email']
        utilisateur = db[COLLECTION_NAME1].find_one({'email': email, 'type': 'client'})

        if utilisateur:
            updated_client = {
                'email': email,
                'nom': request.form['nom'],
                'prenom': request.form['prenom'],
                'ID_Client': utilisateur['ID_Client']
            }
            db[COLLECTION_NAME2].update_one({'_id': ObjectId(id)}, {'$set': updated_client})
            return redirect(url_for('get_clients'))
        else:
            return "Utilisateur non trouvé ou n'est pas un client", 404

    # Récupérer les emails des utilisateurs de type client
    utilisateurs_clients = list(db[COLLECTION_NAME1].find({'type': 'client'}, {'email': 1, '_id': 0}))
    return render_template('edit_client.html', client=client, utilisateurs_clients=utilisateurs_clients)

@app.route('/client/delete/<id>')
def delete_client(id):
    db[COLLECTION_NAME2].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_clients'))

# Proprietaire Routes
@app.route('/proprietaires')
def get_proprietaires():
    proprietaires = list(db[COLLECTION_NAME4].find())
    return render_template('proprietaires.html', proprietaires=proprietaires)

@app.route('/proprietaire/<id>')
def get_proprietaire(id):
    proprietaire = db[COLLECTION_NAME4].find_one({'_id': ObjectId(id)})
    return render_template('proprietaire.html', proprietaire=proprietaire)

@app.route('/proprietaire/create', methods=['GET', 'POST'])
def create_proprietaire():
    if request.method == 'POST':
        email = request.form['email']
        utilisateur = db[COLLECTION_NAME1].find_one({'email': email, 'type': 'proprietaire'})

        if utilisateur:
            proprietaire = {
                'email': email,
                'ID_Proprietaire': utilisateur['ID_Proprietaire'],
                'nom': request.form['nom'],
                'prenom': request.form['prenom'],
                'location': request.form['location'],
                'description': request.form['description'],
                'quantite': int(request.form['quantite'])
            }
            db[COLLECTION_NAME4].insert_one(proprietaire)
            return redirect(url_for('get_proprietaires'))
        else:
            return "Utilisateur non trouvé ou n'est pas un propriétaire", 404

    # Récupérer les emails des utilisateurs de type propriétaire
    utilisateurs_proprietaires = list(db[COLLECTION_NAME1].find({'type': 'proprietaire'}, {'email': 1, '_id': 0}))
    return render_template('create_proprietaire.html', utilisateurs_proprietaires=utilisateurs_proprietaires)

@app.route('/proprietaire/edit/<id>', methods=['GET', 'POST'])
def edit_proprietaire(id):
    proprietaire = db[COLLECTION_NAME4].find_one({'_id': ObjectId(id)})
    if not proprietaire:
        return "Propriétaire non trouvé", 404

    if request.method == 'POST':
        email = request.form['email']
        utilisateur = db[COLLECTION_NAME1].find_one({'email': email, 'type': 'proprietaire'})

        if utilisateur:
            updated_proprietaire = {
                'email': email,
                'ID_Proprietaire': utilisateur['ID_Proprietaire'],
                'nom': request.form['nom'],
                'prenom': request.form['prenom'],
                'location': request.form['location'],
                'description': request.form['description'],
                'quantite': int(request.form['quantite'])
            }
            db[COLLECTION_NAME4].update_one({'_id': ObjectId(id)}, {'$set': updated_proprietaire})
            return redirect(url_for('get_proprietaires'))
        else:
            return "Utilisateur non trouvé ou n'est pas un propriétaire", 404

    # Récupérer les emails des utilisateurs de type propriétaire
    utilisateurs_proprietaires = list(db[COLLECTION_NAME1].find({'type': 'proprietaire'}, {'email': 1, '_id': 0}))
    return render_template('edit_proprietaire.html', proprietaire=proprietaire, utilisateurs_proprietaires=utilisateurs_proprietaires)

@app.route('/proprietaire/delete/<id>')
def delete_proprietaire(id):
    db[COLLECTION_NAME4].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_proprietaires'))

@app.route('/demandes')
def get_demandes():
    demandes = list(db[COLLECTION_NAME3].aggregate([
        {
            '$lookup': {
                'from': COLLECTION_NAME2,
                'localField': 'ID_Client',
                'foreignField': 'ID_Client',
                'as': 'client_info'
            }
        },
        {
            '$lookup': {
                'from': COLLECTION_NAME4,
                'localField': 'ID_Proprietaire',
                'foreignField': 'ID_Proprietaire',
                'as': 'proprietaire_info'
            }
        }
    ]))
    
    for demande in demandes:
        demande['client_info'] = demande['client_info'][0] if demande['client_info'] else {}
        demande['proprietaire_info'] = demande['proprietaire_info'][0] if demande['proprietaire_info'] else {}
        
    return render_template('demandes.html', demandes=demandes)

@app.route('/demande/<id>')
def get_demande(id):
    demande = db[COLLECTION_NAME3].aggregate([
        {
            '$match': {'_id': ObjectId(id)}
        },
        {
            '$lookup': {
                'from': COLLECTION_NAME2,
                'localField': 'ID_Client',
                'foreignField': 'ID_Client',
                'as': 'client_info'
            }
        },
        {
            '$lookup': {
                'from': COLLECTION_NAME4,
                'localField': 'ID_Proprietaire',
                'foreignField': 'ID_Proprietaire',
                'as': 'proprietaire_info'
            }
        },
        {
            '$limit': 1  # We expect only one document
        }
    ])

    demande = list(demande)
    if not demande:
        return "Demande non trouvée", 404

    demande = demande[0]
    demande['client_info'] = demande['client_info'][0] if demande['client_info'] else {}
    demande['proprietaire_info'] = demande['proprietaire_info'][0] if demande['proprietaire_info'] else {}

    return render_template('demande.html', demande=demande)

@app.route('/demande/create', methods=['GET', 'POST'])
def create_demande():
    if request.method == 'POST':
        client_email = request.form['client_email']
        proprietaire_email = request.form['proprietaire_email']
        
        client = db[COLLECTION_NAME2].find_one({'email': client_email})
        proprietaire = db[COLLECTION_NAME4].find_one({'email': proprietaire_email})
        
        demande = {
            'ID_Client': client['ID_Client'],
            'ID_Proprietaire': proprietaire['ID_Proprietaire'],
            'quantite': int(request.form['quantite']),
            'etat': request.form['etat']
        }
        db[COLLECTION_NAME3].insert_one(demande)
        return redirect(url_for('get_demandes'))

    clients = list(db[COLLECTION_NAME2].find())
    proprietaires = list(db[COLLECTION_NAME4].find())
    return render_template('create_demande.html', clients=clients, proprietaires=proprietaires)

@app.route('/demande/edit/<id>', methods=['GET', 'POST'])
def edit_demande(id):
    demande = db[COLLECTION_NAME3].find_one({'_id': ObjectId(id)})
    if request.method == 'POST':
        client_email = request.form['client_email']
        proprietaire_email = request.form['proprietaire_email']
        
        client = db[COLLECTION_NAME2].find_one({'email': client_email})
        proprietaire = db[COLLECTION_NAME4].find_one({'email': proprietaire_email})

        updated_demande = {
            'ID_Client': client['ID_Client'],
            'ID_Proprietaire': proprietaire['ID_Proprietaire'],
            'quantite': int(request.form['quantite']),
            'etat': request.form['etat']
        }
        db[COLLECTION_NAME3].update_one({'_id': ObjectId(id)}, {'$set': updated_demande})
        return redirect(url_for('get_demandes'))

    clients = list(db[COLLECTION_NAME2].find())
    proprietaires = list(db[COLLECTION_NAME4].find())

    client_info = db[COLLECTION_NAME2].find_one({'ID_Client': demande['ID_Client']})
    proprietaire_info = db[COLLECTION_NAME4].find_one({'ID_Proprietaire': demande['ID_Proprietaire']})

    return render_template('edit_demande.html', demande=demande, clients=clients, proprietaires=proprietaires, client_info=client_info, proprietaire_info=proprietaire_info)

@app.route('/demande/delete/<id>')
def delete_demande(id):
    db[COLLECTION_NAME3].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_demandes'))

if __name__ == '__main__':
    app.run(debug=True)
