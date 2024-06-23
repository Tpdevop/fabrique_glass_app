from flask import Flask, request, jsonify, render_template, redirect, url_for
from flask_pymongo import PyMongo
from bson.objectid import ObjectId

app = Flask(__name__)

app.config["MONGO_URI"] = "mongodb+srv://medleminehaj:22482188@mycluster.j2cqkjb.mongodb.net/myapp?retryWrites=true&w=majority&appName=mycluster"
mongo = PyMongo(app)

COLLECTION_NAME1 = "Utilisateurs"
COLLECTION_NAME2 = "Client"
COLLECTION_NAME3 = "Demande"
COLLECTION_NAME4 = "Proprietaire"

@app.route('/')
def home():
    return render_template('home.html', title="Accueil")

# CRUD pour les Utilisateurs
@app.route('/utilisateurs', methods=['GET'])
def get_utilisateurs():
    utilisateurs = mongo.db[COLLECTION_NAME1].find()
    result = [{**user, '_id': str(user['_id'])} for user in utilisateurs]
    return render_template('utilisateurs.html', utilisateurs=result, title="Utilisateurs")

@app.route('/utilisateurs/<id>', methods=['GET'])
def get_utilisateur(id):
    utilisateur = mongo.db[COLLECTION_NAME1].find_one({'_id': ObjectId(id)})
    if utilisateur:
        utilisateur['_id'] = str(utilisateur['_id'])
        return render_template('utilisateur.html', utilisateur=utilisateur, title="Utilisateur")
    else:
        return jsonify({"message": "Utilisateur non trouvé"}), 404

@app.route('/utilisateurs/create', methods=['GET', 'POST'])
def create_utilisateur():
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME1].insert_one(data)
        return redirect(url_for('get_utilisateurs'))
    return render_template('create_utilisateur.html', title="Créer Utilisateur")

@app.route('/utilisateurs/<id>/edit', methods=['GET', 'POST'])
def edit_utilisateur(id):
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME1].update_one({'_id': ObjectId(id)}, {'$set': data})
        return redirect(url_for('get_utilisateurs'))
    utilisateur = mongo.db[COLLECTION_NAME1].find_one({'_id': ObjectId(id)})
    if utilisateur:
        utilisateur['_id'] = str(utilisateur['_id'])
        return render_template('edit_utilisateur.html', utilisateur=utilisateur, title="Modifier Utilisateur")
    else:
        return jsonify({"message": "Utilisateur non trouvé"}), 404

@app.route('/utilisateurs/<id>/delete', methods=['GET'])
def delete_utilisateur(id):
    mongo.db[COLLECTION_NAME1].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_utilisateurs'))

# CRUD pour les Clients
@app.route('/clients', methods=['GET'])
def get_clients():
    clients = mongo.db[COLLECTION_NAME2].find()
    result = [{**client, '_id': str(client['_id'])} for client in clients]
    return render_template('clients.html', clients=result, title="Clients")

@app.route('/clients/<id>', methods=['GET'])
def get_client(id):
    client = mongo.db[COLLECTION_NAME2].find_one({'_id': ObjectId(id)})
    if client:
        client['_id'] = str(client['_id'])
        return render_template('client.html', client=client, title="Client")
    else:
        return jsonify({"message": "Client non trouvé"}), 404

@app.route('/clients/create', methods=['GET', 'POST'])
def create_client():
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME2].insert_one(data)
        return redirect(url_for('get_clients'))
    return render_template('create_client.html', title="Créer Client")

@app.route('/clients/<id>/edit', methods=['GET', 'POST'])
def edit_client(id):
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME2].update_one({'_id': ObjectId(id)}, {'$set': data})
        return redirect(url_for('get_clients'))
    client = mongo.db[COLLECTION_NAME2].find_one({'_id': ObjectId(id)})
    if client:
        client['_id'] = str(client['_id'])
        return render_template('edit_client.html', client=client, title="Modifier Client")
    else:
        return jsonify({"message": "Client non trouvé"}), 404

@app.route('/clients/<id>/delete', methods=['GET'])
def delete_client(id):
    mongo.db[COLLECTION_NAME2].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_clients'))

# CRUD pour les Demandes
@app.route('/demandes', methods=['GET'])
def get_demandes():
    demandes = mongo.db[COLLECTION_NAME3].find()
    result = [{**demande, '_id': str(demande['_id'])} for demande in demandes]
    return render_template('demandes.html', demandes=result, title="Demandes")

@app.route('/demandes/<id>', methods=['GET'])
def get_demande(id):
    demande = mongo.db[COLLECTION_NAME3].find_one({'_id': ObjectId(id)})
    if demande:
        demande['_id'] = str(demande['_id'])
        return render_template('demande.html', demande=demande, title="Demande")
    else:
        return jsonify({"message": "Demande non trouvée"}), 404

@app.route('/demandes/create', methods=['GET', 'POST'])
def create_demande():
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME3].insert_one(data)
        return redirect(url_for('get_demandes'))
    return render_template('create_demande.html', title="Créer Demande")

@app.route('/demandes/<id>/edit', methods=['GET', 'POST'])
def edit_demande(id):
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME3].update_one({'_id': ObjectId(id)}, {'$set': data})
        return redirect(url_for('get_demandes'))
    demande = mongo.db[COLLECTION_NAME3].find_one({'_id': ObjectId(id)})
    if demande:
        demande['_id'] = str(demande['_id'])
        return render_template('edit_demande.html', demande=demande, title="Modifier Demande")
    else:
        return jsonify({"message": "Demande non trouvée"}), 404

@app.route('/demandes/<id>/delete', methods=['GET'])
def delete_demande(id):
    mongo.db[COLLECTION_NAME3].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_demandes'))

# CRUD pour les Propriétaires
@app.route('/proprietaires', methods=['GET'])
def get_proprietaires():
    proprietaires = mongo.db[COLLECTION_NAME4].find()
    result = [{**proprietaire, '_id': str(proprietaire['_id'])} for proprietaire in proprietaires]
    return render_template('proprietaires.html', proprietaires=result, title="Propriétaires")

@app.route('/proprietaires/<id>', methods=['GET'])
def get_proprietaire(id):
    proprietaire = mongo.db[COLLECTION_NAME4].find_one({'_id': ObjectId(id)})
    if proprietaire:
        proprietaire['_id'] = str(proprietaire['_id'])
        return render_template('proprietaire.html', proprietaire=proprietaire, title="Propriétaire")
    else:
        return jsonify({"message": "Propriétaire non trouvé"}), 404

@app.route('/proprietaires/create', methods=['GET', 'POST'])
def create_proprietaire():
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME4].insert_one(data)
        return redirect(url_for('get_proprietaires'))
    return render_template('create_proprietaire.html', title="Créer Propriétaire")

@app.route('/proprietaires/<id>/edit', methods=['GET', 'POST'])
def edit_proprietaire(id):
    if request.method == 'POST':
        data = request.form.to_dict()
        mongo.db[COLLECTION_NAME4].update_one({'_id': ObjectId(id)}, {'$set': data})
        return redirect(url_for('get_proprietaires'))
    proprietaire = mongo.db[COLLECTION_NAME4].find_one({'_id': ObjectId(id)})
    if proprietaire:
        proprietaire['_id'] = str(proprietaire['_id'])
        return render_template('edit_proprietaire.html', proprietaire=proprietaire, title="Modifier Propriétaire")
    else:
        return jsonify({"message": "Propriétaire non trouvé"}), 404

@app.route('/proprietaires/<id>/delete', methods=['GET'])
def delete_proprietaire(id):
    mongo.db[COLLECTION_NAME4].delete_one({'_id': ObjectId(id)})
    return redirect(url_for('get_proprietaires'))

# Démarrer l'application
if __name__ == '__main__':
    app.run(debug=True)
