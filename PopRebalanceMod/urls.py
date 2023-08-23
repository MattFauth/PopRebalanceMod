from django.contrib import admin
from django.urls import path
from pop_mod import views

# Define URL patterns and map them to view functions
urlpatterns = [
    path('upload/', views.upload_files, name='upload_files'),
    path('count/', views.count_population, name='count_population'),
    path('scale/', views.scale_population, name='scale_population'),
]
