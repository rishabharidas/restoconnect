# Resto Platform - Website CMS & Section-Based Builder

---

## 1. Philosophy: Editorial Restaurant Storefront

A restaurant website is a diner's first sensory impression of the brand. As mandated by the product vision:
- The homepage **must NOT** look like an administrative POS terminal or generic e-commerce grid.
- It must present an **editorial, Michelin-grade aesthetic** inspired by leading luxury culinary showcases:
  - Generous whitespace and typography.
  - Large-format dish photography with subtle zoom/hover interactions.
  - Sourcing philosophy (farm-to-table, charcoal smoking, slow dum simmering).
  - Chef heritage and restaurant history.
  - Ambience gallery (terrace, dining hall, open kitchen, bar).
  - Clear operating hours, location maps, and dining guidelines.
- Ordering and reservations are seamlessly offered via **configurable action widgets**.

---

## 2. Section Registry & Data Model

Every restaurant homepage is stored in `restoapp.website_pages` with an ordered collection of sections in `restoapp.website_sections`.

### Standard Registered Section Types:

1. `hero`:
   - Large hero visual, headline, subheading, primary action button.
2. `story`:
   - Chef story, founding heritage, culinary philosophy, and sourcing ethics.
3. `cuisine_highlights`:
   - Visual cards spotlighting signature cooking styles (e.g., *Royal Awadhi Curries*, *Artisanal Tandoor Kebabs*, *Botanical Mocktails*).
4. `signature_dishes`:
   - Curated showcase of award-winning menu items with preparation notes.
5. `atmosphere_gallery`:
   - Responsive photo mosaic of dining spaces and dining hall vibes.
6. `hours_location`:
   - Lunch/Dinner operating hours, address, Google Maps link, and facility badges.
7. `action_widget`:
   - Embeddable widget offering 1-click Table Booking, Online Delivery Tray, or Dine-in QR Scanner.
8. `custom_html`:
   - Sandboxed promotional section allowing custom HTML/CSS safely.

---

## 3. Secure HTML Sandboxing Specification

To allow restaurant owners to paste custom promotional HTML without risking XSS or cross-tenant session hijacking:
1. **Sanitization:** HTML is stripped of dangerous attributes (`onload`, `onerror`, `javascript:` protocols).
2. **Iframe Isolation:** Rendered in an isolated iframe with:
   ```html
   <iframe
     sandbox="allow-scripts"
     srcdoc="<!DOCTYPE html><html>...</html>"
     class="w-full border-0 overflow-hidden"
   ></iframe>
   ```
   Crucially, `allow-same-origin` is **omitted**, preventing the iframe from accessing:
   - `window.localStorage`
   - `document.cookie`
   - `fetch()` requests carrying the parent's authentication credentials.
