// indexDB.js

const DB_NAME = 'myDatabase';
const DB_VERSION = 1;
const STORE_NAME = 'myStore';

export function openDatabase() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);
        request.onerror = (event) => {
            reject('Error opening database');
        };

        request.onsuccess = (event) => {
            const db = event.target.result;
            resolve(db);
        };
        request.onupgradeneeded = (event) => {
            const db = event.target.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, { keyPath: 'id' });
            }
        };
    });
}

export function saveData(obj) {
    return new Promise(async (resolve, reject) => {
        try {
            const db = await openDatabase();
            const transaction = db.transaction([STORE_NAME], 'readwrite');
            const store = transaction.objectStore(STORE_NAME);
            // 添加数据到 IndexedDB
            const request = store.put(obj );
            request.onsuccess = () => {
                resolve('Data saved successfully');
            };
            request.onerror = () => {
                reject('Error saving data');
            };
        } catch (error) {
            reject(error);
        }
    });
}

export function fetchData(key) {
    return new Promise(async (resolve, reject) => {
        try {
            const db = await openDatabase();
            const transaction = db.transaction([STORE_NAME], 'readonly');
            const store = transaction.objectStore(STORE_NAME);
            const request = store.get(key);
            request.onsuccess = () => {
                resolve(request.result);
            };
            request.onerror = () => {
                reject('Error fetching data');
            };
        } catch (error) {
            reject(error);
        }
    });
}
