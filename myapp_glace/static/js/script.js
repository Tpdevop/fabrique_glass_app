document.addEventListener("DOMContentLoaded", function() {
    console.log("JavaScript is loaded.");

    document.querySelectorAll('a[href*="delete"]').forEach(function(element) {
        element.addEventListener('click', function(event) {
            if (!confirm('Êtes-vous sûr de vouloir supprimer cet élément?')) {
                event.preventDefault();
            }
        });
    });

    document.getElementById('type')?.addEventListener('change', function () {
        var proprietaireFields = document.getElementById('proprietaire_fields');
        if (this.value == 'proprietaire') {
            proprietaireFields.style.display = 'block';
        } else {
            proprietaireFields.style.display = 'none';
        }
    });
});
