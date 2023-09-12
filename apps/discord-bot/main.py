import discord, os, time
import extra_functions, main_tests


main_tests.setEnvars()

bot = discord.Bot()

@bot.event
async def on_ready():
    print(f"{bot.user} is ready and online!")

# async def get_animal_types(ctx: discord.AutocompleteContext):
#   """
#   Here we will check if 'ctx.options['animal_type']' is a marine or land animal and return respective option choices
#   """
#   animal_type = ctx.options['animal_type']
#   if animal_type == 'Marine':
#     return ['Whale', 'Shark', 'Fish', 'Octopus', 'Turtle']
#   else: # is land animal
#     return ['Snake', 'Wolf', 'Lizard', 'Lion', 'Bird']

# @bot.slash_command(name="animal")
# async def animal_command(
#   ctx: discord.ApplicationContext,
#   animal_type: discord.Option(str, choices=['Marine', 'Land']),
#   animal: discord.Option(str, autocomplete=discord.utils.basic_autocomplete(get_animal_types))
# ):
#   await ctx.respond(f'You picked an animal type of `{animal_type}` that led you to pick `{animal}`!')


@bot.slash_command(name="nasa")
async def nasa_command(
  ctx: discord.ApplicationContext,
  nasa_function: discord.Option(str, choices=["Near Earth Objects", "Astronomy Picture of the Day"]),
  # nasa_results: discord.Option(str, autocomplete=discord.utils.basic_autocomplete(get_nasa_function))
):
  if nasa_function == "Near Earth Objects":
    neo_data = extra_functions.nasa_neo(os.environ["NASA_KEY"])
    await ctx.respond(f"Here's a near Earth object recorded today: \n {neo_data[0]}")
  elif nasa_function == "Astronomy Picture of the Day":
    apod_data = extra_functions.nasa_apod(os.environ["NASA_KEY"])
    await ctx.respond(f"Astronomy Picture of the Day: {apod_data['title']} - {apod_data['date']}\n{apod_data['explanation']}\n{apod_data['hdurl']}")
  else: 
    pass



bot.run(os.environ["DISCORD_TOKEN"])
