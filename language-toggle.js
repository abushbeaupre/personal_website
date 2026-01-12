<script>
// Language toggle functionality
document.addEventListener('DOMContentLoaded', function() {
  // Get saved language preference or default to English
  let currentLang = localStorage.getItem('language') || 'en';
  
  // Apply language on page load
  setLanguage(currentLang);
  
  // Add click handlers to language buttons
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', function() {
      const lang = this.dataset.lang;
      setLanguage(lang);
      localStorage.setItem('language', lang);
    });
  });
});

function setLanguage(lang) {
  // Hide all language content
  document.querySelectorAll('[class*="lang-"]').forEach(el => {
    el.style.display = 'none';
  });
  
  // Show selected language content
  document.querySelectorAll('.lang-' + lang).forEach(el => {
    el.style.display = 'block';
  });
  
  // Update active button state
  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelectorAll('[data-lang="' + lang + '"]').forEach(btn => {
    btn.classList.add('active');
  });
}
</script>
