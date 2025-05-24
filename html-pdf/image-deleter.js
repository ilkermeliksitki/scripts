// Paste this peace of code to browser console
// and it will do the job
document.querySelectorAll('figure').forEach(function(fig) {
    fig.parentNode.removeChild(fig);
});
