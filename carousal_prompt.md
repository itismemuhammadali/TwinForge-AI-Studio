**PROJECT BRIEF: Social Media Carousel Creator Feature**

**CRITICAL: Read this entire brief before writing a single line of code. The previous implementation was completely wrong and needs to be rebuilt from scratch based on this brief. Do not assume anything. Do not add features that are not mentioned here. Do not remove features that are mentioned here. Follow this brief exactly.**

---

**WHAT WAS BUILT BEFORE (WRONG — DO NOT DO THIS):**
- Multiple user images were being combined into a single dark framed image as a grid or collage
- This is completely wrong
- Never combine multiple images into one frame
- Never create a collage
- Never use a dark frame that holds multiple images inside it
- Never auto arrange user photos into any pattern

---

**WHAT A CAROUSEL ACTUALLY IS:**
A carousel is a collection of 5 to 7 completely separate individual images. Think of Instagram carousel posts. When you swipe left on Instagram each image is its own full screen post. They are never merged or combined. Each slide is an independent image that stands alone. The final output of this feature is always 5 completely separate image files that the user can upload one by one to Instagram Facebook or any other social media platform as a carousel post.

---

**TARGET AUDIENCE:**
This app is built specifically for business men and business women. Every image template and category must feel premium professional and aspirational. Even lifestyle and nature images must feel high quality and polished not casual or tourist like. Always keep this target audience in mind for every single decision made in this feature.

---

**EXACT USER FLOW — FOLLOW THIS STEP BY STEP:**

**Step 1 — User uploads their photos**
- User uploads 4 to 5 of their own personal photos from their device
- Store these uploaded photos in memory so they are accessible throughout the entire feature
- These uploaded photos will be used later in the editor as image overlays placed on top of slide backgrounds

**Step 2 — User selects a category and subcategory**
- Show the user the full category and subcategory system described below in this brief
- User selects a main category first
- Then selects one or more subcategories to refine their image search
- Multiple subcategories can be selected at the same time
- User taps Continue when they are done selecting

**Step 3 — Fetch stock photos from Pexels**
- Call the Pexels API using the selected subcategories combined into one search query
- Always append the word professional or premium to every query regardless of what category was selected
- Fetch exactly 5 stock photos
- Do not show these photos to the user for manual selection
- Automatically pass all 5 fetched stock photos directly to the carousel editor screen
- Each stock photo becomes the full screen background of one carousel slide

**Step 4 — Carousel Editor Screen loads**
- Show a horizontal scroll of slide thumbnails at the top of the screen — Slide 1 Slide 2 Slide 3 Slide 4 Slide 5
- The main area below the thumbnails shows the currently selected slide in full size
- Each slide has its own stock photo as its full screen background image
- The background image fills the entire slide
- The background image cannot be moved resized or deleted by the user
- User starts on Slide 1 by default

**Step 5 — User edits each slide individually using overlays**
- The user edits each slide by adding two types of overlays on top of the background image
- Overlays only exist on the slide they were added to
- Adding an overlay on slide 1 never affects slide 2 or any other slide
- When user switches slides all overlays on the previous slide are saved exactly as they were
- When user comes back to a slide all overlays are exactly where they left them

**OVERLAY TYPE 1 — Image Overlay (User's own uploaded photo)**
- User taps the Add Photo button in the toolbar
- A picker opens showing all the photos the user uploaded in Step 1
- User selects one photo from the picker
- That photo appears on the current slide as a floating layer on top of the background
- The photo has visible drag handles on its corners and edges
- User can drag the photo anywhere on the slide
- User can pinch or use corner handles to resize the photo
- User can rotate the photo using a rotation handle
- User can delete the photo overlay by tapping a delete icon that appears on it
- User can add multiple photo overlays on the same slide
- Each photo overlay is completely independent and can be moved and edited separately
- Photo overlays support opacity control so the user can make them more transparent if needed
- User can apply a circular crop or rounded corners to any photo overlay

**OVERLAY TYPE 2 — Text Overlay**
- User taps the Add Text button in the toolbar
- A text input appears where the user types their desired text
- The typed text appears on the current slide as a floating layer on top of everything including photo overlays
- User can drag the text overlay anywhere on the slide
- User can resize the text box by dragging its handles
- Text overlay editing options that must be available:
  - Font family selection with at least 10 font options including bold serif handwriting and modern sans serif styles
  - Font size slider
  - Font color picker with full color spectrum
  - Text alignment options — left center right
  - Bold italic and underline toggles
  - Background color option behind the text — user can add a solid or semi transparent color block behind their text for better readability
  - Text shadow toggle for better visibility on busy photo backgrounds
  - Opacity control for the entire text overlay
- User can add multiple text overlays on the same slide
- Each text overlay is completely independent and can be moved and edited separately
- User can delete any text overlay by tapping a delete icon on it

**OVERLAY LAYER ORDER:**
- Background image is always at the very bottom and cannot be touched
- User photo overlays sit above the background image
- Text overlays always sit on top of everything including photo overlays
- User cannot change the layer order in this version

**OVERLAY TOOLBAR:**
- Show a bottom toolbar on the editor screen with the following buttons always visible:
  - Add Photo button with an icon
  - Add Text button with an icon
  - Undo button that undoes the last action on the current slide only
  - Redo button
- When the user taps and selects a specific overlay show a contextual toolbar above the main toolbar
- If a photo overlay is selected show photo specific options: opacity slider, crop shape toggle, delete button
- If a text overlay is selected show text specific options: font family, font size, font color, alignment, bold, italic, underline, background color, shadow toggle, opacity slider, delete button

**Step 6 — Navigating between slides**
- User taps any slide thumbnail at the top to switch to that slide
- Or user can swipe left and right on the main slide area to move between slides
- The active slide thumbnail is visually highlighted so the user always knows which slide they are on
- Each slide remembers all its overlays and edits completely when the user navigates away and comes back

**Step 7 — Download**
- User taps the Download button when they are done editing all slides
- The app renders each slide as a separate full resolution PNG image
- Layers are flattened onto each slide in this exact order: background image first at the bottom, then photo overlays on top, then text overlays on top of everything
- All 5 PNG files are packaged into a single ZIP file named carousel.zip
- The files inside the ZIP are named slide1.png slide2.png slide3.png slide4.png slide5.png
- The ZIP file is downloaded to the user's device
- The user can then take those 5 images and post them as a carousel on Instagram Facebook or any other social media platform

---

**DATA STRUCTURE — THIS IS EXACTLY HOW THE DATA SHOULD BE STRUCTURED:**

```
Carousel {
  slides: [
    Slide {
      id: 1,
      backgroundImage: "https://pexels.com/photo/example1.jpg",
      overlays: [
        ImageOverlay {
          type: "image",
          imageUrl: "user_uploaded_photo_1.jpg",
          x: 100,
          y: 150,
          width: 200,
          height: 200,
          rotation: 0,
          opacity: 1.0,
          cropShape: "rectangle"
        },
        TextOverlay {
          type: "text",
          text: "Your text here",
          x: 50,
          y: 300,
          width: 300,
          height: 60,
          fontSize: 24,
          fontFamily: "Montserrat",
          fontColor: "#ffffff",
          alignment: "center",
          bold: false,
          italic: false,
          underline: false,
          backgroundColor: "transparent",
          shadow: false,
          opacity: 1.0
        }
      ]
    },
    Slide {
      id: 2,
      backgroundImage: "https://pexels.com/photo/example2.jpg",
      overlays: []
    },
    Slide {
      id: 3,
      backgroundImage: "https://pexels.com/photo/example3.jpg",
      overlays: []
    },
    Slide {
      id: 4,
      backgroundImage: "https://pexels.com/photo/example4.jpg",
      overlays: []
    },
    Slide {
      id: 5,
      backgroundImage: "https://pexels.com/photo/example5.jpg",
      overlays: []
    }
  ]
}
```

---

**CATEGORY AND SUBCATEGORY SYSTEM:**

Do not remove or simplify any part of this. Keep every single category and subcategory exactly as listed. Do not add categories that are not here. Do not remove categories that are here.

```
Categories {

  Business Men and Business Women {
    subcategories: [
      "Office and Workspace",
      "Team and Meetings",
      "Technology and Laptops",
      "Finance and Money",
      "Presentation and Strategy",
      "Coffee and Work Culture",
      "City and Corporate",
      "Networking and Events",
      "Leadership and Coaching",
      "Entrepreneurship",
      "Luxury Business Lifestyle",
      "Vineyard and Wine Business"
    ]
  },

  Nature {
    subcategories: [
      "Mountains",
      "Beach and Sea",
      "Sunset and Sunrise",
      "Waterfall",
      "Forest",
      "Desert",
      "Vineyard and Countryside",
      "Lakes and Rivers",
      "Flowers and Gardens",
      "Snow and Winter Landscapes"
    ]
  },

  Travel {
    subcategories: [
      "Luxury Hotels",
      "City Skylines",
      "Airports and Transit",
      "Exotic Destinations",
      "Road Trips",
      "Vineyard and Wine Country Travel",
      "Cruise and Ocean Travel",
      "Mountain Retreats",
      "Cultural and Heritage Sites"
    ]
  },

  Minimalist {
    subcategories: [
      "White and Clean",
      "Dark and Moody",
      "Pastel and Soft",
      "Geometric and Abstract",
      "Vineyard and Rustic Minimal",
      "Luxury Minimal",
      "Black and White"
    ]
  },

  Fashion and Lifestyle {
    subcategories: [
      "Luxury and Premium",
      "Fitness and Wellness",
      "Food and Dining",
      "Vineyard and Wine Lifestyle",
      "Beauty and Skincare",
      "Home and Interior Design",
      "Mindfulness and Meditation",
      "Streetwear and Urban"
    ]
  },

  Food and Beverage {
    subcategories: [
      "Fine Dining",
      "Coffee and Cafes",
      "Vineyard and Wine",
      "Cocktails and Drinks",
      "Healthy and Organic",
      "Desserts and Pastry",
      "Street Food",
      "Cooking and Kitchen"
    ]
  },

  Architecture and Interiors {
    subcategories: [
      "Luxury Homes",
      "Modern Architecture",
      "Vineyard Estates and Villas",
      "Office Interiors",
      "Hotels and Resorts",
      "Industrial and Urban Spaces",
      "Historic Buildings"
    ]
  },

  Motivation and Personal Brand {
    subcategories: [
      "Quotes and Typography Backgrounds",
      "Sunrise and New Beginnings",
      "Vineyard and Reflection",
      "Achievement and Success",
      "Books and Learning",
      "Journaling and Planning"
    ]
  }

}
```

---

**PEXELS API QUERY EXAMPLES:**

```
Business Men and Business Women > Office and Workspace
Query: "office workspace professional"

Business Men and Business Women > Finance and Money
Query: "finance money professional"

Business Men and Business Women > Vineyard and Wine Business
Query: "vineyard wine business professional"

Business Men and Business Women > Office and Workspace + Vineyard and Wine Business
Query: "office workspace vineyard wine professional"

Nature > Mountains
Query: "mountains nature professional"

Nature > Mountains + Beach and Sea
Query: "mountains beach nature professional"

Nature > Vineyard and Countryside
Query: "vineyard countryside nature professional"

Travel > Luxury Hotels + Vineyard and Wine Country Travel
Query: "luxury hotel vineyard wine travel professional"

Minimalist > Dark and Moody
Query: "dark moody minimalist professional"

Minimalist > Vineyard and Rustic Minimal
Query: "vineyard rustic minimalist professional"

Food and Beverage > Vineyard and Wine
Query: "vineyard wine food beverage professional"

Fashion and Lifestyle > Vineyard and Wine Lifestyle
Query: "vineyard wine lifestyle professional"

Architecture and Interiors > Vineyard Estates and Villas
Query: "vineyard estate villa architecture professional"

Motivation and Personal Brand > Vineyard and Reflection
Query: "vineyard reflection motivation professional"
```

---

**RULES FOR PEXELS IMAGE FETCHING:**
- Always fetch exactly 5 images regardless of how many subcategories are selected
- Always append professional or premium to every search query no matter what
- Never show low quality casual or tourist style images
- If multiple subcategories are selected combine their keywords into one single query
- If Pexels returns poor quality results fall back to a broader version of the same query
- Images must always feel aspirational and premium since every user of this app is a business professional

---

**UI RULES FOR CATEGORY SCREEN:**
- Show main categories as large cards with an icon and label
- When user taps a main category expand it to show its subcategories
- Show subcategories as chips or tags that can be toggled on and off
- Multiple subcategories can be selected at the same time across the same main category
- Selected subcategories must be visually highlighted so the user always knows what is active
- Show a small label above the subcategory chips that says: Select one or more to refine your images
- Show a Continue button at the bottom of the screen
- The Continue button is disabled and greyed out until at least one subcategory is selected
- Once at least one subcategory is selected the Continue button becomes active
- Tapping Continue fetches the images from Pexels and takes the user to the carousel editor screen

---

**EXPORT RULES — NEVER BREAK THESE:**
- Never combine multiple slides into one single image
- Never create a collage or grid layout
- Never use a dark overlay frame that holds multiple images
- Never auto arrange user photos into any pattern
- Each slide is always one background image plus whatever overlays the user added on top
- The final output is always exactly 5 completely separate PNG files inside one ZIP file
- ZIP file is named carousel.zip
- Individual slide files are named slide1.png slide2.png slide3.png slide4.png slide5.png

---

**SUMMARY IN ONE SENTENCE:**
Build a carousel editor where the user uploads their own photos, selects a category and one or more subcategories from the full category system provided in this brief, the app fetches exactly 5 professional stock photos from Pexels based on those selections, each photo becomes the full screen background of one independent slide, the user edits each slide individually by adding their own photo overlays and text overlays on top of the background using a full featured overlay editor, all edits are saved per slide and never affect other slides, and at the end all 5 slides are exported as completely separate PNG files packaged into a single ZIP file that the user downloads and posts as a carousel on social media.
