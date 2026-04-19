document.addEventListener("DOMContentLoaded", () => {
    // 1. Reveal animations on scroll
    const reveals = document.querySelectorAll(".reveal");
    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add("active");
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.15, rootMargin: "0px 0px -50px 0px" });

    reveals.forEach(reveal => revealObserver.observe(reveal));


    // 2. Interactive Vault Logic
    const vaultCore = document.getElementById("main-vault");
    const vaultIcon = document.getElementById("vault-icon");
    const holoItem = document.getElementById("holo-item");
    const holoIcon = document.getElementById("holo-icon");
    const energyBeam = document.getElementById("energy-beam");
    const featureItems = document.querySelectorAll(".feature-item");

    // Color mapping for different features
    const colors = {
        'security': '#10B981', // Green
        'heartbeat': '#EF4444', // Red
        'handoff': '#3B82F6',   // Blue
        'ai': '#8B5CF6'         // Purple
    };

    let activeItem = null;

    featureItems.forEach(item => {
        // Expand and trigger vault on mouse enter
        item.addEventListener("mouseenter", () => {
            if (activeItem === item) return; // Already active

            // Remove active from all
            featureItems.forEach(i => i.classList.remove("active"));

            // Add to current
            item.classList.add("active");
            activeItem = item;

            // Trigger Vault Animation
            const vaultType = item.getAttribute("data-vault-type");
            const iconName = item.getAttribute("data-icon");
            const color = colors[vaultType] || '#6366F1';

            // "Unlock" the vault
            vaultCore.classList.add("unlocked");

            // Change icon to unlock momentarily
            vaultIcon.setAttribute("name", "lock-open");

            // Change hologram content and color
            holoIcon.setAttribute("name", iconName);
            holoIcon.style.color = color;
            holoIcon.style.filter = `drop-shadow(0 0 20px ${color})`;

            // Change beam and border colors to match feature theme
            energyBeam.style.background = `linear-gradient(90deg, ${color} 0%, transparent 100%)`;
            vaultCore.style.boxShadow = `0 0 60px ${color}33`; // Append hex opacity

            // Re-fire animation by removing and adding class quickly
            holoItem.classList.remove("popped");
            void holoItem.offsetWidth; // Trigger reflow
            holoItem.classList.add("popped");
        });

        // We don't want to reset on mouseleave immediately so the accordion stays open 
        // until the user hovers over another item. 
        // But if they leave the whole accordion area, we can close it.
    });

    const accordionContainer = document.querySelector(".feature-accordion");
    if (accordionContainer) {
        accordionContainer.addEventListener("mouseleave", () => {
            // Reset everything
            featureItems.forEach(i => i.classList.remove("active"));
            activeItem = null;

            // Lock the vault back up
            vaultCore.classList.remove("unlocked");
            vaultIcon.setAttribute("name", "lock-closed");
            vaultCore.style.boxShadow = `0 0 40px rgba(99,102,241,0.1)`; // Reset to default faint glow
        });
    }

    // 3. Mobile Navigation Menu
    const mobileToggle = document.getElementById("mobile-toggle");
    const navLinks = document.getElementById("nav-links");

    if (mobileToggle && navLinks) {
        mobileToggle.addEventListener("click", () => {
            navLinks.classList.toggle("active");
            const icon = mobileToggle.querySelector("ion-icon");
            if (navLinks.classList.contains("active")) {
                icon.setAttribute("name", "close-outline");
            } else {
                icon.setAttribute("name", "menu-outline");
            }
        });

        // Close mobile menu when clicking a link
        navLinks.querySelectorAll("a").forEach(link => {
            link.addEventListener("click", () => {
                navLinks.classList.remove("active");
                mobileToggle.querySelector("ion-icon").setAttribute("name", "menu-outline");
            });
        });
    }

});
