from django.shortcuts import render
from django.http import JsonResponse
import os
from django.core.files.storage import FileSystemStorage


# Utility function to parse and count population from a file
def parse_file(filepath):
    total_size = 0
    with open(filepath, 'r') as file:
        lines = file.readlines()

    for line in lines:
        if 'size = ' in line:
            size_str = line.split('=')[1].split('#')[0].strip()
            try:
                size_value = int(size_str)
                total_size += size_value
            except ValueError as e:
                print(f"Skipping line due to error: {e}. Line content: {line.strip()}")
    return total_size

# File Upload Endpoint
def upload_files(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        fs = FileSystemStorage()
        for uploaded_file in uploaded_files:
            filename = fs.save(uploaded_file.name, uploaded_file)
        return JsonResponse({'message': 'Files uploaded successfully'})

# Count Population Endpoint
def count_population(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        fs = FileSystemStorage()
        grand_total_size = 0  # Initialize the grand total size variable
        # Loop through the list of files and sum up the 'size' values
        for uploaded_file in uploaded_files:
            filepath = fs.save(uploaded_file.name, uploaded_file)
            total_size = parse_file(fs.path(filepath))
            print(f"Total size in {uploaded_file.name}: {total_size}")
            grand_total_size += total_size
        print(f"Grand total size across all files: {grand_total_size}")
        return JsonResponse({'total_population': grand_total_size})

# Utility function to scale population in a file
def scale_file_population(filepath, scaling_factor):
    updated_lines = []
    with open(filepath, 'r') as file:
        lines = file.readlines()
    for line in lines:
        if 'size = ' in line:
            original_size_str = line.split('=')[1].split('#')[0].strip()
            original_size = int(original_size_str)
            scaled_size = int(original_size * scaling_factor)
            comment_part = line.split('#')[1] if '#' in line else ''
            updated_line = f"size = {scaled_size} #{comment_part}" if comment_part else f"size = {scaled_size}\n"
            updated_lines.append(updated_line)
        else:
            updated_lines.append(line)
    with open(filepath, 'w') as file:
        file.writelines(updated_lines)

# Django view function to handle population scaling
def scale_population(request):
    if request.method == 'POST':
        uploaded_files = request.FILES.getlist('files')
        fs = FileSystemStorage()
        # Calculate the scaling factor (this could be passed in as a parameter)
        target_world_population = 500_000_000
        current_total_population = 0  # Replace with the current total population from your files
        scaling_factor = target_world_population / current_total_population

        # Apply the scaling factor to each file
        for uploaded_file in uploaded_files:
            filepath = fs.save(uploaded_file.name, uploaded_file)
            scale_file_population(fs.path(filepath), scaling_factor)
            print(f"Scaled population sizes in {uploaded_file.name}.")
        return JsonResponse({'message': 'Population scaled'})
