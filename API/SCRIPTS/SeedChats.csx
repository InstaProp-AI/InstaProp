#!/usr/bin/env dotnet-script
#r "nuget: Microsoft.EntityFrameworkCore, 9.0.0"
#r "nuget: Npgsql.EntityFrameworkCore.PostgreSQL, 9.0.0"
#r "nuget: BCrypt.Net-Next, 4.0.3"
#r "nuget: System.Text.Json, 9.0.0"

using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

// This is a simplified direct seeding approach
// For now, let's modify Program.cs to add a command-line argument

