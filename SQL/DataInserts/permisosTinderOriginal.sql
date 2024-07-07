/* Permisos de tier = Plus */

SELECT insert_new_permission('infLikes', 'Likes ilimitados', 'Plus'); 
SELECT insert_new_permission('infRewinds', 'Rewinds ilimitados', 'Plus'); 
SELECT insert_new_permission('passport', 'Passport™ te da acceso a cualquier ubicación', 'Plus'); 
SELECT insert_new_permission('adBlock', 'Ocultar publicidad', 'Plus'); 
SELECT insert_new_permission('incognite', 'Activar incognito', 'Plus');

/* Permisos de tier = Gold */

SELECT insert_new_permission('semSuperlikes', 'Super Likes semanales', 'Gold');
SELECT insert_new_permission('1freeBoost', '1 Boost gratis al mes', 'Gold');
SELECT insert_new_permission('whoLikesU', 'Descubre a quien le gustas', 'Gold');
SELECT insert_new_permission('newTopPicks', 'Nuevos Top Picks todos los dias', 'Gold');
SELECT insert_old_tier_old_permissions('Gold', ARRAY['infLikes', 'infRewinds', 'passport', 'adBlock', 'incognite']);

SELECT 

/* Permisos de tier = Platinum */
SELECT insert_new_permission('sendMsgEveryone', 'Envia un mensaje antes de hacer match', 'Platinum');
SELECT insert_new_permission('prefLikes', 'Likes con preferencia', 'Platinum');
SELECT insert_new_permission('last7DaysHistoryLikes', 'Acceso a los Likes que enviaste en los ultimos 7 dias', 'Platinum');
SELECT insert_old_tier_old_permissions('Platinum', ARRAY['infLikes', 'infRewinds', 'passport', 'adBlock', 'incognite', 'semSuperlikes', 'whoLikesU', 'newTopPicks']);
