from sqlalchemy import Column, String, Integer, Float, Boolean, Text, DateTime, JSON
from sqlalchemy.orm import DeclarativeBase
from datetime import datetime


class Base(DeclarativeBase):
    pass


class Source(Base):
    __tablename__ = "sources"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    url = Column(String, nullable=False)
    type = Column(String, nullable=False)  # newspaper | journalist | website
    country = Column(String)
    language = Column(String)
    city = Column(String)
    reliability = Column(Integer, default=3)  # 1-5
    tags = Column(JSON, default=list)
    affiliation = Column(String, nullable=True)
    twitter_handle = Column(String, nullable=True)
    enabled = Column(Boolean, default=True)
    last_fetched = Column(DateTime, nullable=True)
    error_count = Column(Integer, default=0)


class Article(Base):
    __tablename__ = "articles"

    id = Column(String, primary_key=True)  # hash of url
    source_id = Column(String, nullable=False)
    title = Column(String, nullable=False)
    url = Column(String, nullable=False)
    summary = Column(Text, nullable=True)
    published_at = Column(DateTime, nullable=False)
    fetched_at = Column(DateTime, default=datetime.utcnow)
    author = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    # Scoring
    source_reliability = Column(Integer, default=3)
    clickbait_score = Column(Float, default=0.0)   # 0-1, higher = more clickbait
    final_score = Column(Float, default=3.0)        # computed overall score
    clickbait_flags = Column(JSON, default=list)    # list of detected flags
