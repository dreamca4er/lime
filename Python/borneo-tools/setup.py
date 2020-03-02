import setuptools

setuptools.setup(
    name="borneo-tools",
    version="1.6",
    author="Andrei Goncharov",
    author_email="author@example.com",
    description="Usefull functions for borneo-related stuff",
    packages=setuptools.find_packages(),
    install_requires=['requests', 'pyodbc'],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6,<3.8',
)