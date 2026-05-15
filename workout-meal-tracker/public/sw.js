// Service Worker for Fitness Tracker PWA
const CACHE_NAME = 'fitness-tracker-v1';
const OFFLINE_URL = '/offline.html';

// Files to cache for offline functionality
const urlsToCache = [
  '/',
  '/static/js/bundle.js',
  '/static/css/main.css',
  '/manifest.json',
  '/offline.html',
  // Add other critical assets
];

// Install event - cache files
self.addEventListener('install', (event) => {
  console.log('[SW] Install event');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[SW] Caching app shell');
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('[SW] Skip waiting');
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activate event');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('[SW] Claiming clients');
      return self.clients.claim();
    })
  );
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', (event) => {
  // Handle navigation requests
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .catch(() => {
          return caches.open(CACHE_NAME)
            .then((cache) => {
              return cache.match(OFFLINE_URL);
            });
        })
    );
    return;
  }

  // Handle API requests with network-first strategy
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          // Cache successful API responses
          if (response.status === 200) {
            const responseClone = response.clone();
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseClone);
              });
          }
          return response;
        })
        .catch(() => {
          // Return cached response if available
          return caches.match(event.request);
        })
    );
    return;
  }

  // Handle other requests with cache-first strategy
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request)
          .then((response) => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }

            const responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });

            return response;
          });
      })
  );
});

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync:', event.tag);
  
  if (event.tag === 'workout-sync') {
    event.waitUntil(syncWorkouts());
  }
  
  if (event.tag === 'meal-sync') {
    event.waitUntil(syncMeals());
  }
});

// Push notifications
self.addEventListener('push', (event) => {
  console.log('[SW] Push received:', event);
  
  const options = {
    body: event.data ? event.data.text() : 'New notification',
    icon: '/logo192.png',
    badge: '/logo192.png',
    vibrate: [200, 100, 200],
    actions: [
      {
        action: 'open',
        title: 'Open App',
        icon: '/logo192.png'
      },
      {
        action: 'close',
        title: 'Close',
        icon: '/logo192.png'
      }
    ],
    tag: 'fitness-tracker',
    renotify: true
  };

  event.waitUntil(
    self.registration.showNotification('Fitness Tracker', options)
  );
});

// Notification click handler
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification click:', event);
  
  event.notification.close();

  if (event.action === 'open') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Helper functions for background sync
async function syncWorkouts() {
  try {
    // Get pending workouts from IndexedDB
    const pendingWorkouts = await getPendingWorkouts();
    
    for (const workout of pendingWorkouts) {
      try {
        await fetch('/api/workouts', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(workout.data)
        });
        
        // Remove from pending list
        await removePendingWorkout(workout.id);
      } catch (error) {
        console.error('[SW] Failed to sync workout:', error);
      }
    }
  } catch (error) {
    console.error('[SW] Workout sync failed:', error);
  }
}

async function syncMeals() {
  try {
    // Get pending meals from IndexedDB
    const pendingMeals = await getPendingMeals();
    
    for (const meal of pendingMeals) {
      try {
        await fetch('/api/meals', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(meal.data)
        });
        
        // Remove from pending list
        await removePendingMeal(meal.id);
      } catch (error) {
        console.error('[SW] Failed to sync meal:', error);
      }
    }
  } catch (error) {
    console.error('[SW] Meal sync failed:', error);
  }
}

// IndexedDB helpers (simplified - would need full implementation)
async function getPendingWorkouts() {
  // Implementation would use IndexedDB to get pending workouts
  return [];
}

async function removePendingWorkout(id) {
  // Implementation would remove workout from IndexedDB
}

async function getPendingMeals() {
  // Implementation would use IndexedDB to get pending meals
  return [];
}

async function removePendingMeal(id) {
  // Implementation would remove meal from IndexedDB
}