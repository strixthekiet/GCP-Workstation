import os
from flask import Flask, request, jsonify, render_template
from google.cloud import compute_v1
import time

# Rename app to vm_manager to match the entry point in Terraform
app = Flask(__name__)

# Configuration
PROJECT_ID = os.environ.get("PROJECT_ID")
ZONE = os.environ.get("ZONE")
PASSWORD = os.environ.get("PASSWORD")
NPM_GATEWAY_NAME = os.environ.get("NPM_GATEWAY_NAME", "npm-gateway")

def get_instances_client():
    return compute_v1.InstancesClient()

def list_instances():
    client = get_instances_client()
    request = compute_v1.ListInstancesRequest(project=PROJECT_ID, zone=ZONE)
    return client.list(request=request)

def get_vms_internal():
    vms = []
    gateway_status = "UNKNOWN"
    
    for instance in list_instances():
        if instance.name == NPM_GATEWAY_NAME:
            gateway_status = instance.status
        else:
            vms.append({
                "name": instance.name,
                "status": instance.status
            })
    # Sort VMs by name for consistent display
    vms.sort(key=lambda x: x['name'])
    return {"vms": vms, "gateway_status": gateway_status}

@app.route('/')
def index():
    try:
        data = get_vms_internal()
        return render_template('index.html', vms=data['vms'], gateway_status=data['gateway_status'])
    except Exception as e:
        return f"Error loading VMs: {str(e)}", 500

@app.route('/api/vms', methods=['GET'])
def get_vms():
    try:
        return jsonify(get_vms_internal())
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/verify', methods=['POST'])
def verify_password():
    data = request.get_json()
    if data.get('password') == PASSWORD:
        return jsonify({"status": "valid"})
    return jsonify({"status": "invalid"}), 401

@app.route('/api/vms/<name>/toggle', methods=['POST'])
def toggle_vm(name):
    data = request.get_json()
    if not data or data.get('password') != PASSWORD:
        return jsonify({"error": "Unauthorized"}), 401
    
    action = data.get('action')
    client = get_instances_client()
    
    try:
        if action == 'start':
            op = client.start(project=PROJECT_ID, zone=ZONE, instance=name)
            op.result() # Wait for operation
            
            # Check if gateway needs to be started
            gw_instance = client.get(project=PROJECT_ID, zone=ZONE, instance=NPM_GATEWAY_NAME)
            if gw_instance.status != 'RUNNING':
                client.start(project=PROJECT_ID, zone=ZONE, instance=NPM_GATEWAY_NAME)

        elif action == 'stop':
            op = client.stop(project=PROJECT_ID, zone=ZONE, instance=name)
            op.result() # Wait for operation
            
            # Check if any other VMs are running
            any_running = False
            for instance in list_instances():
                if instance.name != NPM_GATEWAY_NAME and instance.name != name and instance.status == 'RUNNING':
                    any_running = True
                    break
            
            # If no other VMs are running, stop the gateway
            if not any_running:
                 client.stop(project=PROJECT_ID, zone=ZONE, instance=NPM_GATEWAY_NAME)

        return jsonify({"status": "success"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Cloud Functions entry point
def vm_manager(request):
    """
    HTTP Cloud Function entry point that wraps the Flask app.
    """
    # Create a request context using the environment from the Cloud Function request
    with app.request_context(request.environ):
        # Dispatch the request to the Flask app
        return app.full_dispatch_request()
