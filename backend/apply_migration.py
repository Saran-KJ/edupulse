from database import engine, Base
from models import *
print("Applying database schema changes (creating indexes)...")
Base.metadata.create_all(bind=engine)
print("Done!")
